/*
 * generated by Xtext 2.13.0-SNAPSHOT
 */
package io.typefox.yang.ide

import org.eclipse.xtext.ide.editor.contentassist.IdeContentProposalProvider
import io.typefox.yang.ide.completion.YangCompletionProvider
import io.typefox.yang.ide.contentassist.antlr.lexer.InternalYangLexer
import io.typefox.yang.ide.contentassist.antlr.lexer.jflex.JFlexBasedInternalYangLexer

/**
 * Use this class to register ide components.
 */
class YangIdeModule extends AbstractYangIdeModule {
	
	def Class<? extends IdeContentProposalProvider> bindIdeContentProposalProvider() {
		return YangCompletionProvider
	}
	
	def Class<? extends InternalYangLexer> bindInternalYangLexer() {
		return JFlexBasedInternalYangLexer;
	}
	
}
