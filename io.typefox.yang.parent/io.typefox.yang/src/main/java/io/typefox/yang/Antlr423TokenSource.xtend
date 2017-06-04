package io.typefox.yang

import org.antlr.runtime.CharStream
import org.antlr.runtime.Token
import org.antlr.runtime.TokenSource

class Antlr423TokenSource implements TokenSource {

	org.antlr.v4.runtime.TokenSource delegate
	int[] tokenTypeMap
	
	new (org.antlr.v4.runtime.TokenSource delegate, int[] tokenTypeMap) {
		this.delegate = delegate
		this.tokenTypeMap = tokenTypeMap
	}

	override getSourceName() {
		return this.delegate.sourceName
	}

	override nextToken() {
		val antrl4Token = this.delegate.nextToken
		return new Antlr423Token(antrl4Token, this.tokenTypeMap)
	}
	
	static class Antlr423Token implements Token {

		org.antlr.v4.runtime.Token delegate
		int[] tokenTypeMap

		new(org.antlr.v4.runtime.Token delegate, int[] tokenTypeMap) {
			this.delegate = delegate
			this.tokenTypeMap = tokenTypeMap
		}

		override getChannel() {
			this.delegate.channel
		}

		override getCharPositionInLine() {
			this.delegate.charPositionInLine
		}

		override getInputStream() {
			return new Antlr423CharStream(this.delegate.inputStream)
		}

		override getLine() {
			return this.delegate.line
		}

		override getText() {
			return this.delegate.text
		}

		override getTokenIndex() {
			return this.delegate.tokenIndex
		}

		override getType() {
			val type = this.delegate.type 
			return this.tokenTypeMap.get(type)
		}

		override setChannel(int channel) {
			throw new UnsupportedOperationException("unmodifiable")
		}

		override setCharPositionInLine(int pos) {
			throw new UnsupportedOperationException("unmodifiable")
		}

		override setInputStream(CharStream input) {
			throw new UnsupportedOperationException("unmodifiable")
		}

		override setLine(int line) {
			throw new UnsupportedOperationException("unmodifiable")
		}

		override setText(String text) {
			throw new UnsupportedOperationException("unmodifiable")
		}

		override setTokenIndex(int index) {
			throw new UnsupportedOperationException("unmodifiable")
		}

		override setType(int ttype) {
			throw new UnsupportedOperationException("unmodifiable")
		}

	}
	
	static class Antlr423CharStream implements CharStream {
		org.antlr.v4.runtime.CharStream delegate
	
		new(org.antlr.v4.runtime.CharStream delegate) {
			this.delegate = delegate
		}
	
		override LT(int i) {
			throw new UnsupportedOperationException("TODO: auto-generated method stub")
		}
	
		override getCharPositionInLine() {
			throw new UnsupportedOperationException("TODO: auto-generated method stub")
		}
	
		override getLine() {
			throw new UnsupportedOperationException("TODO: auto-generated method stub")
		}
	
		override setCharPositionInLine(int pos) {
			throw new UnsupportedOperationException("TODO: auto-generated method stub")
		}
	
		override setLine(int line) {
			throw new UnsupportedOperationException("TODO: auto-generated method stub")
		}
	
		override substring(int start, int stop) {
			throw new UnsupportedOperationException("TODO: auto-generated method stub")
		}
	
		override LA(int i) {
			throw new UnsupportedOperationException("TODO: auto-generated method stub")
		}
	
		override consume() {
			throw new UnsupportedOperationException("TODO: auto-generated method stub")
		}
	
		override getSourceName() {
			this.delegate.sourceName
		}
	
		override index() {
			throw new UnsupportedOperationException("TODO: auto-generated method stub")
		}
	
		override mark() {
			throw new UnsupportedOperationException("TODO: auto-generated method stub")
		}
	
		override release(int marker) {
			throw new UnsupportedOperationException("TODO: auto-generated method stub")
		}
	
		override rewind() {
			throw new UnsupportedOperationException("TODO: auto-generated method stub")
		}
	
		override rewind(int marker) {
			throw new UnsupportedOperationException("TODO: auto-generated method stub")
		}
	
		override seek(int index) {
			throw new UnsupportedOperationException("TODO: auto-generated method stub")
		}
	
		override size() {
			throw new UnsupportedOperationException("TODO: auto-generated method stub")
		}
	
	}
}

