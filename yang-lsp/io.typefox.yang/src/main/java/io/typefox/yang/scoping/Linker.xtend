package io.typefox.yang.scoping

import com.google.inject.Inject
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EReference
import org.eclipse.emf.ecore.InternalEObject
import org.eclipse.emf.ecore.util.EcoreUtil
import org.eclipse.xtext.linking.impl.LinkingHelper
import org.eclipse.xtext.linking.lazy.LazyURIEncoder
import org.eclipse.xtext.naming.IQualifiedNameConverter
import org.eclipse.xtext.naming.QualifiedName
import org.eclipse.xtext.resource.IEObjectDescription
import org.eclipse.xtext.nodemodel.util.NodeModelUtils

class Linker {

	@Inject LinkingHelper linkingHelper
	@Inject LazyURIEncoder lazyURIEncoder
	@Inject IQualifiedNameConverter qualifiedNameConverter

	def <T> T link(EObject element, EReference reference, (QualifiedName)=>IEObjectDescription resolver) {
		val qname = getLinkingName(element, reference)
		if (qname !== null) {
			val candidate = resolver.apply(qname)
			if (candidate !== null) {
				val resolved = EcoreUtil.resolve(candidate.getEObjectOrProxy, element)
				element.eSet(reference, resolved)
				return resolved as T
			}
		}
		return element.eGet(reference, false) as InternalEObject as T
	}

	def QualifiedName getLinkingName(EObject element, EReference reference) {
		val proxy = element.eGet(reference, false) as InternalEObject
		if (proxy !== null) {
			if (proxy.eIsProxy) {
				val uri = proxy.eProxyURI
				if (uri.trimFragment == element.eResource.getURI &&
					lazyURIEncoder.isCrossLinkFragment(element.eResource, uri.fragment)) {
					val node = lazyURIEncoder.getNode(element, uri.fragment)
					val symbol = linkingHelper.getCrossRefNodeAsString(node, true)
					return qualifiedNameConverter.toQualifiedName(symbol)
				} else {
					// regular proxy let's resolve here
					element.eGet(reference, true)
				}
			} else {
				val symbol = NodeModelUtils.findNodesForFeature(element, reference).map[leafNodes.filter[!isHidden].map[getText].join("")].join("")
				return qualifiedNameConverter.toQualifiedName(symbol)
			}
		}
		return null
	}
}
