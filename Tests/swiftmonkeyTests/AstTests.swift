//
//  AstTests.swift
//  swiftmonkeyTests
//
//  Created by Ter on 4/1/19.
//

import XCTest
@testable import swiftmonkey

class AstTests: XCTestCase {

    func testPerformanceExample() {
        let program = Program(statements: [
            LetStatement(token: Token(type: TokenType.LET, literal: "let"),
                         name: Identifier(token: Token(type: TokenType.IDENT, literal: "myVar"), value: "myVar"),
                         value: Identifier(token: Token(type: TokenType.IDENT, literal: "anotherVar"), value: "anotherVar"))
            ])
        
        let expectedResult = "let myVar = anotherVar;"
        XCTAssertTrue(expectedResult == program.string())
    }

}
