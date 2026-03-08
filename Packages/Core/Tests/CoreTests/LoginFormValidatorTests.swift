import Testing
@testable import Core

@Test func validationFailsForEmptyEmail() {
    let sut = LoginFormValidator()

    #expect(sut.validate(email: "", password: "password123") == .emptyEmail)
}

@Test func validationFailsForEmptyPassword() {
    let sut = LoginFormValidator()

    #expect(sut.validate(email: "demo@retailrescue.app", password: "") == .emptyPassword)
}

@Test func validationFailsForInvalidEmail() {
    let sut = LoginFormValidator()

    #expect(sut.validate(email: "demo", password: "password123") == .invalidEmail)
}

@Test func validationFailsForWeakPassword() {
    let sut = LoginFormValidator()

    #expect(sut.validate(email: "demo@retailrescue.app", password: "1234") == .weakPassword)
}

@Test func validationPassesForValidInput() {
    let sut = LoginFormValidator()

    #expect(sut.validate(email: "demo@retailrescue.app", password: "password123") == nil)
}
