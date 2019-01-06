//
//  Parser.swift
//  swiftmonkey
//
//  Created by Ter on 3/1/19.
//

import Foundation

typealias prefixParseFn = () -> Expression
typealias infixParseFn = (Expression) -> Expression

enum OperatorOrder:Int {
    case LOWEST = 1
    case EQUALS // ==
    case LESSGREATER // > or <
    case SUM // +
    case PRODUCT // *
    case PREFIX // -X or !X
    case CALL // myFunc(X)
}

var precedences:[TokenType:OperatorOrder] = [.EQUAL: .EQUALS,
                                             .NOTEQUAL: .EQUALS,
                                             .GREATER: .LESSGREATER,
                                             .LESSTHAN: .LESSGREATER,
                                             .PLUS: .SUM,
                                             .MINUS: .SUM,
                                             .SLASH: .PRODUCT,
                                             .ASTERISK: .PRODUCT,]

public class Parser {
    let lexer:Lexer
    var curToken:Token
    var peekToken:Token
    var errors:[String] = []
    var prefixParseFunctions:[TokenType:prefixParseFn] = [:]
    var infixParseFunctions:[TokenType:infixParseFn] = [:]
    var peekPercedence: OperatorOrder {
        get {
            if let percedence = precedences[peekToken.tokenType] {
                return percedence
            }
            return OperatorOrder.LOWEST
        }
    }
    var curPercedence: OperatorOrder {
        get {
            if let percedence = precedences[curToken.tokenType] {
                return percedence
            }
            return OperatorOrder.LOWEST
        }
    }

    public init(lexer l:Lexer) {
        lexer = l
        curToken = l.nextToken()
        peekToken = l.nextToken()
        registerPrefix(type: TokenType.IDENT, function: parseIdentifier)
        registerPrefix(type: TokenType.INT, function: parseIntegerLiteral)
        
        registerPrefix(type: TokenType.BANG, function: parsePrefixExpression)
        registerPrefix(type: TokenType.MINUS, function: parsePrefixExpression)
        
        registerInfix(type: TokenType.PLUS, function: parseInfixExpression)
        registerInfix(type: TokenType.MINUS, function: parseInfixExpression)
        registerInfix(type: TokenType.SLASH, function: parseInfixExpression)
        registerInfix(type: TokenType.ASTERISK, function: parseInfixExpression)
        registerInfix(type: TokenType.EQUAL, function: parseInfixExpression)
        registerInfix(type: TokenType.NOTEQUAL, function: parseInfixExpression)
        registerInfix(type: TokenType.LESSTHAN, function: parseInfixExpression)
        registerInfix(type: TokenType.GREATER, function: parseInfixExpression)
    }
    
    func nextToken() {
        curToken = peekToken
        peekToken = lexer.nextToken()
    }
    
    public func parseProgram() -> Program {
        var program = Program()
        
        while curToken.tokenType != TokenType.EOF {
            if let stmt = parseStatement() {
                program.statements.append(stmt)
            }
            nextToken()
        }
        return program
    }
    
    func parseStatement() -> Statement? {
        switch curToken.tokenType {
        case .LET:
            return parseLetStatement()
        case .RETURN:
            return parseReturnStatement()
        default:
            return parseExpressStatement()
        }
    }
    
    func parseExpressStatement() -> ExpressionStatement {
        var statement = ExpressionStatement(token: curToken, expression: nil)
        statement.expression = parseExpression(precedence: OperatorOrder.LOWEST)
        if isPeekTokenType(type: TokenType.SEMICOLON) {
            nextToken()
        }
        return statement
    }
    
    func parseReturnStatement() -> ReturnStatement? {
        let statement  = ReturnStatement(token: curToken, returnValue: nil)
        nextToken()
        while isCurrentTokenType(type: TokenType.SEMICOLON) == false {
            nextToken()
        }
        return statement
    }
    
    func parseLetStatement() -> LetStatement? {
        let token = curToken
        if expectPeek(type: TokenType.IDENT) == false {
            return nil
        }
        
        let name = Identifier(token: curToken, value: curToken.literal)
        if expectPeek(type: TokenType.ASSIGN) == false {
            return nil
        }
        
        while isCurrentTokenType(type: TokenType.SEMICOLON) == false {
            nextToken()
        }
        
        return LetStatement(token: token, name: name, value: nil)
    }
    
    func isCurrentTokenType(type: TokenType) -> Bool {
       return curToken.tokenType == type
    }

    func isPeekTokenType(type: TokenType) -> Bool {
        return peekToken.tokenType == type
    }
    
    func expectPeek(type: TokenType) -> Bool {
        if isPeekTokenType(type: type) {
            nextToken()
            return true
        } else {
            peekError(type: type)
            return false
        }
    }
    
    func peekError(type: TokenType) {
        let error = "expected next token to be "
            + peekToken.tokenType.rawValue
            + ", got " + type.rawValue + " instead."
        errors.append(error)
    }
    
    func registerPrefix(type: TokenType, function: @escaping prefixParseFn) {
        prefixParseFunctions[type] = function
    }
    
    func registerInfix(type: TokenType, function: @escaping infixParseFn) {
        infixParseFunctions[type] = function
    }
    
    func parseExpression(precedence: OperatorOrder) -> Expression? {
        guard let prefix = prefixParseFunctions[curToken.tokenType] else {
            noPrefixParseFunctionError(tokenType: curToken.tokenType)
            return nil
        }
        var leftExp = prefix()
        while ( isPeekTokenType(type: TokenType.SEMICOLON) == false && precedence.rawValue < peekPercedence.rawValue) {
            let infix = infixParseFunctions[peekToken.tokenType]
            if infix == nil {
                return leftExp
            }
            nextToken()
            leftExp = infix!(leftExp)
        }
        return leftExp
    }
    
    func parseIdentifier() -> Expression {
        return Identifier(token: curToken, value: curToken.literal)
    }
    
    func parseIntegerLiteral() -> Expression {
        if let intValue = Int(curToken.literal) {
            return IntegerLiteral(token: curToken, value: intValue)
        } else {
            let error = "could not parse \(curToken.literal) as integer"
            errors.append(error)
            return IntegerLiteral(token: curToken, value: 0)
        }
    }
    
    func parsePrefixExpression() -> Expression {
        let token = curToken
        nextToken()
        let expression = PrefixExpression(token: token,
                                          operatorLiteral: token.literal,
                                          right: parseExpression(precedence: OperatorOrder.PREFIX))
        return expression
    }
    
    func parseInfixExpression(left: Expression) -> Expression {
        
        let token = curToken
        let precedence = curPercedence
        nextToken()
        let expression = InfixExpression(token: token,
                                          left: left,
                                          operatorLiteral: token.literal,
                                          right: parseExpression(precedence: precedence))
        return expression
    }

    
    func noPrefixParseFunctionError(tokenType: TokenType){
        let message = "no prefix parse function for \(tokenType.rawValue) found"
        errors.append(message)
    }
    
    
}
