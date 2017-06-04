package io.typefox.yang

import com.google.common.io.CharStreams
import io.typefox.yang.parser.antlr.lexer.InternalYangLexer
import java.io.InputStreamReader
import java.util.Map
import org.antlr.runtime.CharStream
import org.antlr.runtime.RecognitionException
import org.antlr.runtime.Token
import org.antlr.v4.runtime.misc.Interval

class Antlr4BasedInternalYangLexer extends InternalYangLexer {
	
	def static void main(String[] args) {
		tokenMap.forEach[p1, p2|
			println(p2+"-"+p1)
		]
	}
	
	static int[] tokenMap = initializeTokenIdMap('io/typefox/yang/YangLexer.tokens', 'io/typefox/yang/parser/antlr/lexer/InternalYangLexer.tokens')
	
	static def int[] initializeTokenIdMap(String from, String to) {
		val fromEntries = readMap(from)
		val toEntries = readMap(to)
		val result = newIntArrayOfSize(fromEntries.values.max+1)
		// EOF 
		result.set(0, -1)
		fromEntries.forEach[name, id|
			var match = toEntries.get(name)
			if (match === null) {
				match = toEntries.get('RULE_'+name)
			}
			if (match === null) {
				if (!name.startsWith("'"))
					System.err.println("Couldn't find rule "+name)
			} else {
				result.set(id, match)	
			}
		]
		return result 
	}
	
	static def Map<String,Integer> readMap(String resource) {
		val resourceAsStream = Antlr4BasedInternalYangLexer.classLoader.getResourceAsStream(resource)
		val inputStreamReader = new InputStreamReader(resourceAsStream)
		return CharStreams.readLines(inputStreamReader)
			.toMap([split('=').head], [Integer.parseInt(split('=').get(1))])
	}
	
	CharStream charStream

	override void mTokens() throws RecognitionException {
		throw new UnsupportedOperationException()
	}

	override CharStream getCharStream() {
		return this.charStream
	}

	override Token nextToken() {
		return delegate.nextToken()
	}
	
	Antlr423TokenSource delegate

	override void setCharStream(CharStream input) {
		this.charStream = input
		this.reset()
	}

	override void reset() {
		val antlr324CharStream = new Antlr324CharStream(this.charStream)
		this.delegate = new Antlr423TokenSource(new YangLexer(antlr324CharStream), tokenMap)
	}
}

class Antlr324CharStream implements org.antlr.v4.runtime.CharStream {
	
	CharStream delegate
	
	new (CharStream delegate) {
		this.delegate = delegate
	}
	
	override getText(Interval interval) {
		this.delegate.substring(interval.a, interval.b)
	}
	
	override LA(int i) {
		this.delegate.LA(i)
	}
	
	override consume() {
		this.delegate.consume
	}
	
	override getSourceName() {
		this.delegate.sourceName
	}
	
	override index() {
		this.delegate.index
	}
	
	override mark() {
		this.delegate.mark
	}
	
	override release(int marker) {
		this.delegate.release(marker)
	}
	
	override seek(int index) {
		this.delegate.seek(index)
	}
	
	override size() {
		this.delegate.size
	}
	
}
