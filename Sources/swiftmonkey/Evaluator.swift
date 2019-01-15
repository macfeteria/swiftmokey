//
//  Evaluator.swift
//  swiftmonkey
//
//  Created by Ter on 10/1/19.
//

import Foundation

public struct Evaluator {
    static let TRUE = BooleanObj(value: true)
    static let FALSE = BooleanObj(value: false)
    static let NULL = NullObj()

    public func eval(node: Node, environment env: Environment) -> Object {
        switch node {
        case is Program:
            let program = node as! Program
            return eval(program: program, environment: env)
        case is ExpressionStatement:
            let ex = node as! ExpressionStatement
            return eval(node: ex.expression!, environment: env)
        case is IntegerLiteral:
            let int = node as! IntegerLiteral
            return IntegerObj(value: int.value)
        case is Boolean:
            let boolean = node as! Boolean
            return boolean.value ? Evaluator.TRUE : Evaluator.FALSE
        case is PrefixExpression:
            let pre = node as! PrefixExpression
            let right = eval(node: pre.right!, environment: env)
            if isError(obj: right) { return right }
            return evalPrefixExpression(oper: pre.operatorLiteral, right: right)
        case is InfixExpression:
            let infix = node as! InfixExpression
            let left = eval(node: infix.left, environment: env)
            if isError(obj: left) { return left }
            let right = eval(node: infix.right!, environment: env)
            if isError(obj: right) { return right }
            return evalInfixExpression(oper: infix.operatorLiteral, left: left, right: right)
        case is BlockStatement:
            let block = node as! BlockStatement
            return evalBlockStatement(block: block, environment: env)
        case is IfExpression:
            let ifEx = node as! IfExpression
            return evalIfExpression(expression: ifEx, environment: env)
        case is ReturnStatement:
            let returnStmt = node as! ReturnStatement
            let value = eval(node:returnStmt.returnValue!, environment: env)
            if isError(obj: value) { return value }
            return ReturnValueObj(value: value)
        case is LetStatement:
            let letStmt = node as! LetStatement
            let value = eval(node: letStmt.value!, environment: env)
            if isError(obj: value) { return value }
            return env.set(name: letStmt.name.value, object: value)
        case is Identifier:
            let iden = node as! Identifier
            return evalIdentifier(node: iden, environment: env)
        default:
            return Evaluator.NULL
        }
    }
    
    func evalIdentifier(node: Identifier, environment env: Environment) -> Object {
        let (iden,ok) = env.get(name: node.value)
        if !ok {
            return ErrorObj(message: "identifier not found: \(node.value)")
        }
        return iden
    }
    
    func eval(program:Program, environment env: Environment) -> Object {
        var result: Object = NullObj()
        for s in program.statements {
            result = eval(node: s, environment: env)
            if let returnValue = result as? ReturnValueObj {
                return returnValue.value
            }
            if let error = result as? ErrorObj {
                return error
            }
        }
        return result
    }
    
    func evalBlockStatement(block: BlockStatement, environment env: Environment) -> Object {
        var result: Object = NullObj()
        for s in block.statements {
            result = eval(node: s, environment: env)
            let type = result.type()
            if type == ObjectType.ERROR || type == ObjectType.RETURN_VALUE {
                return result
            }
        }
        return result
    }
    
    func evalInfixExpression(oper: String, left:Object, right: Object) -> Object {
        if left.type() == ObjectType.INTEGER && right.type() == ObjectType.INTEGER {
            return evalIntegerExpression(oper: oper, left: left, right: right)
        }

        if left.type() == ObjectType.BOOLEAN && right.type() == ObjectType.BOOLEAN {
            let leftBool = left as! BooleanObj
            let rightBool = right as! BooleanObj
            if oper == "==" {
                return leftBool.value == rightBool.value ? Evaluator.TRUE : Evaluator.FALSE
            }
            if oper == "!=" {
                return leftBool.value != rightBool.value ? Evaluator.TRUE : Evaluator.FALSE
            }
        }
        if left.type() != right.type() {
            return ErrorObj(message: "type mismatch: \(left.type()) \(oper) \(right.type())")
        }

        return ErrorObj(message: "unknow operator: \(left.type()) \(oper) \(right.type())")
    }

    
    func evalPrefixExpression(oper: String, right: Object) -> Object {
        switch oper {
        case "!" :
            return evalBangOperator(right: right)
        case "-" :
            return evalMinusPrefixOperator(right: right)
        default:
            return ErrorObj(message: "unknow operator: \(oper) \(right.type())")
        }
    }

    func evalIntegerExpression(oper: String, left:Object, right: Object) -> Object {
        let leftValue = (left as! IntegerObj).value
        let rightValue = (right as! IntegerObj).value
        switch oper {
        case "+" :
            return IntegerObj(value: leftValue + rightValue)
        case "-" :
            return IntegerObj(value: leftValue - rightValue)
        case "*" :
            return IntegerObj(value: leftValue * rightValue)
        case "/" :
            return IntegerObj(value: leftValue / rightValue)
        case "<" :
            return leftValue < rightValue ? Evaluator.TRUE : Evaluator.FALSE
        case ">" :
            return leftValue > rightValue ? Evaluator.TRUE : Evaluator.FALSE
        case "==" :
            return leftValue == rightValue ? Evaluator.TRUE : Evaluator.FALSE
        case "!=" :
            return leftValue != rightValue ? Evaluator.TRUE : Evaluator.FALSE
        default:
            return ErrorObj(message: "unknow operator: \(left.type()) \(oper) \(right.type())")
        }
    }
    func evalMinusPrefixOperator(right: Object) -> Object {
        if right.type() != ObjectType.INTEGER {
            return ErrorObj(message: "unknow operator: -\(right.type())")
        }
        let intObj = right as! IntegerObj
        return IntegerObj(value: -intObj.value)
    }
    
    func evalBangOperator(right: Object) -> Object {
        switch right {
        case is BooleanObj:
            let bool = right as! BooleanObj
            return bool.value ? Evaluator.FALSE : Evaluator.TRUE
        case is NullObj:
            return Evaluator.TRUE
        default:
            return Evaluator.FALSE
        }
    }
    
    func evalIfExpression(expression: IfExpression, environment env: Environment) -> Object {
        let condition = eval(node: expression.condition, environment: env)
        if isError(obj: condition) { return condition }
        if isTruthy(obj: condition) {
            return eval(node: expression.consequence, environment: env)
        } else if let alter = expression.alternative {
            return eval(node: alter, environment: env)
        } else {
            return Evaluator.NULL
        }
    }
    
    func isTruthy(obj: Object) -> Bool {
        if obj is NullObj {
            return false
        }
        if let boolObj = obj as? BooleanObj {
          return boolObj.value
        }
        if let intObj = obj as? IntegerObj {
            return intObj.value != 0
        }
        return true
    }
    
    func isError(obj: Object) -> Bool {
        return obj.type() == ObjectType.ERROR
    }
}
