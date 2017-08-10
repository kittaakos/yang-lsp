package io.typefox.yang.ide.completion

import com.google.inject.Inject
import io.typefox.yang.documentation.DocumentationProvider
import io.typefox.yang.scoping.IScopeContext
import io.typefox.yang.scoping.ScopeContext.MapScope
import io.typefox.yang.scoping.ScopeContextProvider
import io.typefox.yang.services.YangGrammarAccess
import io.typefox.yang.validation.SubstatementRuleProvider
import io.typefox.yang.yang.AbstractImport
import io.typefox.yang.yang.AbstractModule
import io.typefox.yang.yang.Description
import io.typefox.yang.yang.Revision
import io.typefox.yang.yang.SchemaNode
import io.typefox.yang.yang.SchemaNodeIdentifier
import io.typefox.yang.yang.Statement
import io.typefox.yang.yang.YangPackage
import org.eclipse.emf.ecore.EClass
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.util.EcoreUtil
import org.eclipse.xtext.AbstractElement
import org.eclipse.xtext.CrossReference
import org.eclipse.xtext.EcoreUtil2
import org.eclipse.xtext.GrammarUtil
import org.eclipse.xtext.Keyword
import org.eclipse.xtext.ParserRule
import org.eclipse.xtext.RuleCall
import org.eclipse.xtext.ide.editor.contentassist.ContentAssistContext
import org.eclipse.xtext.ide.editor.contentassist.ContentAssistEntry
import org.eclipse.xtext.ide.editor.contentassist.IIdeContentProposalAcceptor
import org.eclipse.xtext.ide.editor.contentassist.IdeContentProposalProvider
import org.eclipse.xtext.naming.QualifiedName
import org.eclipse.xtext.resource.IEObjectDescription
import org.eclipse.xtext.scoping.IScope
import org.eclipse.xtext.xtext.CurrentTypeFinder

import static io.typefox.yang.yang.YangPackage.Literals.*

import static extension io.typefox.yang.utils.YangNameUtils.*
import static extension org.eclipse.xtext.EcoreUtil2.*
import org.eclipse.xtext.formatting.IWhitespaceInformationProvider
import io.typefox.yang.yang.Prefix
import io.typefox.yang.yang.Module

class YangContentProposalProvider extends IdeContentProposalProvider {

	static val IGNORED_KEYWORDS = #{'/', '{', ';', '}'}

	@Inject extension CurrentTypeFinder
	@Inject extension DocumentationProvider
	@Inject ScopeContextProvider scopeContextProvider
	@Inject SubstatementRuleProvider ruleProvider
	@Inject YangGrammarAccess grammarAccess
	@Inject IWhitespaceInformationProvider whitespaceInformation

	override protected _createProposals(RuleCall ruleCall, ContentAssistContext context,
		IIdeContentProposalAcceptor acceptor) {
		if (ruleCall.rule.name == 'BUILTIN_TYPE') {
			for (kw : EcoreUtil.getAllContents(ruleCall.rule, false).filter(Keyword).toIterable) {
				createProposals(kw, context, acceptor)
			}
		}
	}
	
	override protected _createProposals(Keyword keyword, ContentAssistContext context, IIdeContentProposalAcceptor acceptor) {
		if (keyword === grammarAccess.importAccess.importKeyword_0 && filterKeyword(keyword, context)) {
			val module = EcoreUtil2.getContainerOfType(context.currentModel, AbstractModule)
			val scopeCtx = scopeContextProvider.getScopeContext(module)
			val indentString = whitespaceInformation.getIndentationInformation(context.resource.URI).indentString
			for (e : scopeCtx.moduleScope.allElements) {
				val m = EcoreUtil.resolve(e.EObjectOrProxy, context.resource) as AbstractModule
				if (m instanceof Module && m !== module) {
					val rev = m.substatements.filter(Revision).sortBy[revision].reverseView.head
					val entry = new ContentAssistEntry() => [
						prefix = context.prefix;
						label = "import "+e.qualifiedName
						proposal = '''
							import «e.qualifiedName» {
								prefix «m.substatements.filter(Prefix).head?.prefix»;
								«IF rev!==null»
									revision-date «rev.revision»;
								«ENDIF»
							}
						'''.toString.replaceAll('  ', indentString);
						description = "module "+m.name
						documentation = m.documentation
						kind = ContentAssistEntry.KIND_MODULE
					];
					acceptor.accept(entry, this.proposalPriorities.getDefaultPriority(entry)+1)
				}
			}
		}
		super._createProposals(keyword, context, acceptor)
	}

	override protected _createProposals(CrossReference reference, ContentAssistContext context,
		IIdeContentProposalAcceptor acceptor) {
		val type = findCurrentTypeAfter(reference)
		if (type instanceof EClass) {
			val ereference = GrammarUtil.getReference(reference, type)
			val currentModel = context.currentModel
			if (ereference !== null && currentModel !== null) {
				if (YangPackage.Literals.SCHEMA_NODE_IDENTIFIER__SCHEMA_NODE === ereference) {
					computeIdentifierRefProposals(reference, context, acceptor)
				} else if (YangPackage.Literals.REVISION_DATE__DATE === ereference) {
					computeRevisionProposals(reference, context, acceptor) 
				} else {
					val scope = scopeProvider.getScope(currentModel, ereference)

					crossrefProposalProvider.lookupCrossReference(scope, reference, context, acceptor,
						getCrossrefFilter(reference, context))
				}
			}
		}
	}
	
	def computeRevisionProposals(CrossReference reference, ContentAssistContext context, IIdeContentProposalAcceptor acceptor) {
		val imp = EcoreUtil2.getContainerOfType(context.currentModel, AbstractImport)
		if (imp !== null && imp.module !== null && !imp.module.eIsProxy) {
			for (rev : imp.module.substatements.filter(Revision)) {
				val entry = this.proposalCreator.createProposal(rev.revision, context) => [
					documentation = rev.substatements.filter(Description).head?.description
					kind = ContentAssistEntry.KIND_REFERENCE
				]
				acceptor.accept(entry, proposalPriorities.getDefaultPriority(entry))
			}
		}
	}

	private def QualifiedName computeNodeSchemaPrefix(EObject object, IScope nodeScope) {
		if (object instanceof SchemaNodeIdentifier) {
			if (object.target === null || object.target.schemaNode.eIsProxy) {
				return QualifiedName.EMPTY;
			}
			val desc = nodeScope.getSingleElement(object.target.schemaNode)
			if (desc !== null) {
				return desc.name
			}
		} else if (object instanceof SchemaNode) {
			val desc = nodeScope.getSingleElement(object)
			if (desc !== null) {
				return desc.name
			}
		} else if (object.eContainer !== null) {
			return computeNodeSchemaPrefix(object.eContainer, nodeScope)
		}
		return QualifiedName.EMPTY
	}

	def computeIdentifierRefProposals(CrossReference reference, ContentAssistContext context,
		IIdeContentProposalAcceptor acceptor) {

		val scopeCtx = scopeContextProvider.findScopeContext(context.currentModel)
		val nodeScope = scopeCtx.schemaNodeScope
		val prefix = computeNodeSchemaPrefix(context.currentModel, nodeScope)
		val isInPath = context.currentModel instanceof SchemaNodeIdentifier
		computeSchemaNodePathProposals(prefix, nodeScope, scopeCtx, context, acceptor)
		if (!isInPath && prefix.segmentCount > 0) {
			// add absolute proposals
			computeSchemaNodePathProposals(QualifiedName.EMPTY, nodeScope, scopeCtx, context, acceptor)
		}
	}

	private def void computeSchemaNodePathProposals(QualifiedName prefix, MapScope nodeScope, IScopeContext scopeCtx,
		ContentAssistContext context, IIdeContentProposalAcceptor acceptor) {
		for (e : nodeScope.allElements.filter[name.startsWith(prefix)]) {
			val suffix = e.name.skipFirst(prefix.segmentCount)
			var name = new StringBuilder()
			for (var i = 0; i < suffix.segmentCount; i++) {
				if (i % 2 === 0) { // module prefix
					val modulePrefix = suffix.getSegment(i)
					if (modulePrefix != scopeCtx.moduleName) {
						val moduleName = suffix.getSegment(i)
						val importPrefix = scopeCtx.importedModules.entrySet.findFirst[value.moduleName == moduleName].
							key
						name.append(importPrefix).append(":")
					}
				} else {
					name.append(suffix.getSegment(i))
					if (i + 1 < suffix.segmentCount) {
						name.append("/")
					}
				}
			}
			if (name.length > 0) {
				val proposalName = if (prefix.segmentCount === 0) {
						"/" + name.toString
					} else {
						name.toString
					}
				val entry = this.proposalCreator.createProposal(proposalName, context) [
					documentation = e.EObjectOrProxy.documentation
					// TODO description, etc.
				]
				acceptor.accept(entry, this.proposalPriorities.getCrossRefPriority(e, entry))
			}
		}
	}

	override protected filterKeyword(Keyword keyword, ContentAssistContext context) {
		if (keyword.statement) {
			val substatementRule = ruleProvider.get(context?.currentModel?.eClass);
			if (substatementRule !== null) {
				val container = context.currentModel as Statement;
				val index = if (context.previousModel === container) {
						0
					} else {
						container.substatements.indexOf(context.previousModel);
					}
				if (index >= 0) {
					val clazz = keyword.value.EClassForName;
					return clazz !== null && substatementRule.canInsert(container, clazz, index);
				}
			}
		}
		return super.filterKeyword(keyword, context) && !IGNORED_KEYWORDS.contains(keyword.value);
	}

	private def isStatement(AbstractElement it) {
		val classifier = getContainerOfType(ParserRule)?.type?.classifier;
		return classifier instanceof EClass && STATEMENT.isSuperTypeOf(classifier as EClass);
	}

	override protected getCrossrefFilter(CrossReference reference, ContentAssistContext context) {
		val scopeCtx = scopeContextProvider.findScopeContext(context.currentModel)
		val localPrefix = scopeCtx.localPrefix
		// filter local qualified names out
		return [ IEObjectDescription desc |
			return desc.name.segmentCount == 1 || desc.name.firstSegment != localPrefix
		]
	}

}
