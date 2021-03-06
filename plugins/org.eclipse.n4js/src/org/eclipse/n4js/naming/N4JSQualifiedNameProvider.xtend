/**
 * Copyright (c) 2016 NumberFour AG.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * Contributors:
 *   NumberFour AG - Initial API and implementation
 */
package org.eclipse.n4js.naming

import org.eclipse.n4js.AnnotationDefinition
import org.eclipse.n4js.n4JS.ExportDeclaration
import org.eclipse.n4js.n4JS.FunctionDeclaration
import org.eclipse.n4js.n4JS.N4TypeDeclaration
import org.eclipse.n4js.n4JS.Script
import org.eclipse.n4js.n4JS.VariableDeclaration
import org.eclipse.n4js.ts.scoping.N4TSQualifiedNameProvider
import org.eclipse.n4js.ts.types.IdentifiableElement
import org.eclipse.n4js.ts.types.TClass
import org.eclipse.n4js.ts.types.TClassifier
import org.eclipse.n4js.ts.types.TEnum
import org.eclipse.n4js.ts.types.TFunction
import org.eclipse.n4js.ts.types.TMember
import org.eclipse.n4js.ts.types.TModule
import org.eclipse.n4js.ts.types.TInterface
import org.eclipse.n4js.ts.types.TVariable
import org.eclipse.n4js.ts.types.Type
import org.eclipse.n4js.ts.types.TypeVariable
import org.eclipse.emf.ecore.EObject
import org.eclipse.xtext.naming.QualifiedName

import static extension org.eclipse.emf.ecore.util.EcoreUtil.*
import static extension org.eclipse.n4js.utils.N4JSLanguageUtils.*

/**
 * Calculates the fully qualified name for the passed in objects.
 * <p>
 * Be very careful when changing anything here as the FQN affects a lot of concepts, including scoping and even typing.
 * That is, elements are often handled differently if they have a qualified name or not.
 */
class N4JSQualifiedNameProvider extends N4TSQualifiedNameProvider {


	/**
	 * For the root element (Script) the resource qualified name is used.
	 * For all other elements the resource qualified name plus the simple
	 * name of the element is used as qualified name.
	 * Exceptions are IdentifiableElement, N4ClassExpression and FunctionExpression
	 * for which only the simple name is returned.
	 * For a ExportDeclaration the qualified name of its contained element is returned.
	 * For a TModule the qualified name is just converted from dots to slashes.
	 */
	override QualifiedName getFullyQualifiedName(EObject it) {
		switch (it) {
			Script:
				module.fullyQualifiedName
			TModule:
				if (qualifiedName !== null) {
					fqnTModule(it)
				}
			N4TypeDeclaration:
				if (name !== null) fqnTypeDeclaration(it)
			FunctionDeclaration:
				if (name !== null && it.eContainer instanceof ExportDeclaration) rootContainer.fullyQualifiedName?.append(name)
			VariableDeclaration:
				if (name !== null && it.eContainer instanceof ExportDeclaration) rootContainer.fullyQualifiedName?.append(name)
			TClass:
				if (name !== null) fqnTClassifier(it)
			TInterface:
				if (name !== null) fqnTClassifier(it)
			TEnum:
				if (name !== null) rootContainer.fullyQualifiedName?.append(exportedName ?: name)
			TFunction:
				if (name !== null && it.exported) rootContainer.fullyQualifiedName?.append(exportedName)
			TVariable:
				if (name !== null && it.exported) rootContainer.fullyQualifiedName?.append(exportedName)
			ExportDeclaration:
				exportedElement?.getFullyQualifiedName
			TypeVariable:
				null
			Type:
				if (name !== null) QualifiedName.create(name)
			TMember:
				null // either null or a real qualified name, but not the simple name! since they cannot be accessed via FQN, we return null
			IdentifiableElement: // including TFormalParameter, and Variable with CatchVariable, FormalParameter, LocalArgumentsVariable
				null
			default:
				null
		}
	}



	private def QualifiedName fqnTModule(TModule module) {

		if ( module.qualifiedName.length != 0 && ! AnnotationDefinition.GLOBAL.hasAnnotation(module)) {
			var plainQN = converter.toQualifiedName(module.qualifiedName);
			if( module.isStaticPolyfillModule ) {
				return prepend(MODULE_POLYFILL_SEGMENT, plainQN)
			}
			return plainQN
		} else {
			return QualifiedName.create(GLOBAL_NAMESPACE_SEGMENT)
		}

	}
	private def QualifiedName fqnTypeDeclaration(N4TypeDeclaration typeDecl) {
		var prefix = typeDecl.rootContainer.fullyQualifiedName;
		if ( typeDecl.isPolyfill || typeDecl.isStaticPolyfill )
		{
			prefix = append(prefix, POLYFILL_SEGMENT);
		}
		val fqn = append(prefix, typeDecl.exportedName ?: typeDecl.name);
		return fqn;
	}

	private def QualifiedName fqnTClassifier(TClassifier tClassifier) {
		var prefix = tClassifier.rootContainer.fullyQualifiedName;
		if (tClassifier.polyfill) {
			prefix = append(prefix, POLYFILL_SEGMENT);
		}
		val fqn = append(prefix, tClassifier.exportedName ?: tClassifier.name);
		return fqn;
	}
}
