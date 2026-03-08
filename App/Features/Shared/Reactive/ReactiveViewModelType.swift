import Foundation

protocol ReactiveViewModelType {
    associatedtype Input
    associatedtype Output

    func transform(input: Input) -> Output
}
