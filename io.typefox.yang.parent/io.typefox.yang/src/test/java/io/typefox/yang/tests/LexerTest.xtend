package io.typefox.yang.tests

import com.google.inject.Inject
import com.google.inject.Provider
import io.typefox.yang.Antlr4BasedInternalYangLexer
import org.antlr.runtime.ANTLRStringStream
import org.eclipse.xtext.parser.antlr.Lexer
import org.eclipse.xtext.testing.InjectWith
import org.eclipse.xtext.testing.XtextRunner
import org.junit.Test
import org.junit.runner.RunWith

import static io.typefox.yang.parser.antlr.internal.InternalYangParser.*
import static org.junit.Assert.*
import org.antlr.runtime.Token

@InjectWith(YangInjectorProvider)
@RunWith(XtextRunner)
class LexerTest {

	@Inject Provider<Antlr4BasedInternalYangLexer> lexer
	
	@Test def void testToken() {
		val l = lexer.get
		l.charStream = new ANTLRStringStream('''
			module 'foo' "212-$556C" 212-$556C {
			  path "module"
			}
		''')
		var t = l.nextToken 
		while (t.type !== Token.EOF) {
			println(''''«t.text»'		«t.line»:«t.charPositionInLine» / type «t.type»''')
			t = l.nextToken
		}
	}

	@Test def void testLexer() {
		val l = lexer.get
		l.charStream = new ANTLRStringStream('''
			module foo 212-$556C {
			  path "module"
			}
		''')
		l.assertNextToken(Module, 'module')
		l.assertNextToken(RULE_WS, ' ')
		l.assertNextToken(RULE_ID, 'foo')
		l.assertNextToken(RULE_WS, ' ')
		l.assertNextToken(RULE_STRING, '212-$556C')
		l.assertNextToken(RULE_WS, ' ')
		l.assertNextToken(LeftCurlyBracket, '{')
		l.assertNextToken(RULE_WS, '\n  ')
		l.assertNextToken(Path, 'path')
		l.assertNextToken(RULE_WS, ' ')
		l.assertNextToken(QuotationMark, '"')
		l.assertNextToken(RULE_ID, 'module')
		l.assertNextToken(QuotationMark, '"')
		l.assertNextToken(RULE_WS, '\n')
		l.assertNextToken(RightCurlyBracket, '}')
	}
	
	
	@Test def void test_DoubleQuotedID() {
		val l = lexer.get
		l.charStream = new ANTLRStringStream('''
			module "foo"
		''')
		l.assertNextToken(Module, 'module')
		l.assertNextToken(RULE_WS, ' ')
		l.assertNextToken(RULE_ID, '"foo"')
	}
	
	@Test def void test_DoubleQuotedStringConcatenation() {
		val l = lexer.get
		l.charStream = new ANTLRStringStream('''
			path "foo"
			    + "bar"
		''')
		l.assertNextToken(Path, 'path')
		l.assertNextToken(RULE_WS, ' ')
		l.assertNextToken(QuotationMark, '"')
		l.assertNextToken(RULE_ID, 'foo')
		l.assertNextToken(RULE_WS, '"\n    + "')
		l.assertNextToken(RULE_ID, 'bar')
		l.assertNextToken(QuotationMark, '"')
	}
	
	@Test def void test_SingleQuotedString() {
		val l = lexer.get
		l.charStream = new ANTLRStringStream('''
			module 'foo-bar42'
		''')
		l.assertNextToken(Module, 'module')
		l.assertNextToken(RULE_WS, ' ')
		l.assertNextToken(RULE_ID, "'foo-bar42'")
	}
	
	
	private def void assertNextToken(Lexer it, int id, String text) {
		val t = nextToken
		assertEquals(text, t.text)
		assertEquals(id, t.type)
	}
	
}
