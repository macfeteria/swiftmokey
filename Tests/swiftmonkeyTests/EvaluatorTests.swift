//
//  EvaluatorTests.swift
//  swiftmonkeyTests
//
//  Created by Ter on 10/1/19.
//

import XCTest
@testable import swiftmonkey

class EvaluatorTests: XCTestCase {
    
    func evaluate(input:String) -> Object {
        let lexer = Lexer(input: input)
        let parser = Parser(lexer: lexer)
        
        let program = parser.parseProgram()
        let evaluated = Evaluator()
        return evaluated.eval(node: program)
    }
    
    func validateIntegerObject(obj:Object, expect: Int) {
        let intObj = obj as! IntegerObj
        XCTAssertTrue(intObj.value == expect, "Expect \(expect) Got \(intObj.value)")
    }
    
    func validateBooleanObject(obj:Object, expect: Bool) {
        let boolObj = obj as! BooleanObj
        XCTAssertTrue(boolObj.value == expect,"Expect \(expect) Got \(boolObj.value)")
    }
    
    func validateNullObject(obj:Object) {
        let nullObj = obj as? NullObj
        XCTAssertNotNil(nullObj)
    }

    func testEvalIntegerExpression () {
        let tests = [(code:"5",expectedValue:5),
                     (code:"10",expectedValue:10),
                     (code:"-10",expectedValue:-10),
                     (code:"-5",expectedValue:-5),
                     
                     (code:"5 + 5 + 5 + 5 -10", expectedValue:10),
                     (code:"2 * 2 * 2 * 2 * 2", expectedValue:32),
                     (code:"-50 + 100 -50", expectedValue:0),
                     (code:"5 * 2 + 10", expectedValue:20),
                     (code:"5 + 2 * 10", expectedValue:25),
                     (code:"50 / 2 * 2 + 10", expectedValue:60),
                     (code:"2 * (5 + 10)", expectedValue:30),
                     (code:"3 * (3 * 3) + 10", expectedValue:37),
                     (code:"3 * 3 * 3 + 10", expectedValue:37),
                     (code:"(5 + 10 * 2 + 15 / 3) * 2 + -10", expectedValue:50),
    
                     ]
        
        for test in tests {
            let resultObj = evaluate(input: test.code)
            validateIntegerObject(obj: resultObj, expect: test.expectedValue)
        }
    }
    
    func testEvalBooleanExpression () {
        let tests = [
                     (code:"true",expectedValue:true),
                     (code:"false",expectedValue:false),
                     
                     (code:"true == true",expectedValue:true),
                     (code:"false == false",expectedValue:true),
                     (code:"true == false",expectedValue:false),
                     (code:"true != false",expectedValue:true),
                     (code:"false != true",expectedValue:true),

                     (code:"1 < 2",expectedValue:true),
                     (code:"1 > 2",expectedValue:false),
                     (code:"1 < 1",expectedValue:false),
                     (code:"1 > 1",expectedValue:false),
                     (code:"1 == 1",expectedValue:true),
                     (code:"1 != 1",expectedValue:false),
                     (code:"1 == 2",expectedValue:false),
                     (code:"1 != 2",expectedValue:true),

                     (code:"(1 < 2) == true",expectedValue:true),
                     (code:"(1 < 2) == false",expectedValue:false),
                     (code:"(1 > 2) == true",expectedValue:false),
                     (code:"(1 > 2) == false",expectedValue:true),

                     (code:"true == (1 < 2)",expectedValue:true),
                     ]
        
        for test in tests {
            let resultObj = evaluate(input: test.code)
            validateBooleanObject(obj: resultObj, expect: test.expectedValue)
        }
    }
    
    func testIfExpression () {
        let tests = [
                     (code:"if (true) { 10 }",expectedValue: 10),
                     (code:"if (false) { 10 }",expectedValue: nil),
                     (code:"if (1) { 10 }",expectedValue: 10),
                     (code:"if (1 < 2) { 10 }",expectedValue: 10),
                     (code:"if (1 > 2) { 10 }",expectedValue: nil),
                     (code:"if (1 > 2) { 10 } else { 20 }",expectedValue: 20),
                     (code:"if (1 < 2) { 10 } else { 20 }",expectedValue: 10),
                     ]
        for test in tests {
            let resultObj = evaluate(input: test.code)
            if let value = test.expectedValue {
                validateIntegerObject(obj: resultObj, expect: value)
            } else {
                validateNullObject(obj: resultObj)
            }
        }
    }
    
    func testBangOperator () {
        let tests = [(code:"!true",expectedValue:false),
                     (code:"!false",expectedValue:true),
                     (code:"!5",expectedValue:false),
                     (code:"!!true",expectedValue:true),
                     (code:"!!false",expectedValue:false),
                     (code:"!!5",expectedValue:true),
                     ]
        
        for test in tests {
            let resultObj = evaluate(input: test.code)
            validateBooleanObject(obj: resultObj, expect: test.expectedValue)
        }
    }
    
    func testReturnStatement () {
        let tests = [
                    (code:"return 10;", expectedValue:10),
                    (code:"return 10; 9;", expectedValue:10),
                    (code:"return 2 * 5; 9;", expectedValue:10),
                    (code:"9; return 2 * 5; 8;", expectedValue:10),
                    (code:"""
                        if ( 10 > 1 ) {
                            if ( 10 > 1 ) {
                                return 10;
                            }
                            return 1;
                        }
                        """, expectedValue: 10),
                    ]
        for test in tests {
            let resultObj = evaluate(input: test.code)
            validateIntegerObject(obj: resultObj, expect: test.expectedValue)
        }
    }

    func testErrorHandling () {
        let tests = [
            (code:"5 + true;", expectedValue:"type mismatch: INTEGER + BOOLEAN"),
            (code:"5 + true; 5;", expectedValue:"type mismatch: INTEGER + BOOLEAN"),
            (code:"-true;", expectedValue:"unknow operator: -BOOLEAN"),
            (code:"true + false;", expectedValue:"unknow operator: BOOLEAN + BOOLEAN"),
            (code:"5; true + false; 5", expectedValue:"unknow operator: BOOLEAN + BOOLEAN"),
            (code:"if (10 > 1) { true + false; }", expectedValue:"unknow operator: BOOLEAN + BOOLEAN"),
            (code:"""
                if ( 10 > 1 ) {
                    if ( 10 > 1 ) {
                        return true + false;
                    }
                    return 1;
                }
                """, expectedValue:"unknow operator: BOOLEAN + BOOLEAN"),
        ]
        for test in tests {
            let resultObj = evaluate(input: test.code)
            XCTAssertTrue(resultObj.inspect() == test.expectedValue, "Expect \(test.expectedValue) Got \(resultObj.inspect())" )
        }
    }

}
