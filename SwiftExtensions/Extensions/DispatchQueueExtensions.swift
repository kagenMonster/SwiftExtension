//
//  DispatchQueueExtensions.swift
//  SwiftExtensions
//
//  Created by Kagen Zhao on 16/9/7.
//  Copyright © 2016年 kagenZhao. All rights reserved.
//

import Foundation

// MARK: - Div
public extension DispatchQueue {
    
    static var userInteractive: DispatchQueue { return DispatchQueue.global(qos: .userInteractive) }
    
    static var userInitiated: DispatchQueue { return DispatchQueue.global(qos: .userInitiated) }
    
    static var utility: DispatchQueue { return DispatchQueue.global(qos: .utility) }
    
    static var background: DispatchQueue { return DispatchQueue.global(qos: .background) }
    
    private static var _tokens: Set<UnsafeRawPointer> = []
    
    
    /// 替代 OC-DispatchOnce
    /// 之所以不用String作为identifier, 因为在多人开发中 可能用到同一个字符串, 用 pointer 比较保险
    /// - Parameters:
    ///   - token: identifier
    ///   - closure: execute
    class func once(_ token: UnsafeRawPointer, execute closure: (() -> ())) {
        
        objc_sync_enter(self); defer { objc_sync_exit(self) }
        
        guard !_tokens.contains(token) else { return }
        
        _tokens.insert(token)
        
        closure()
    }
    
    func after(delay: TimeInterval, execute closure: @escaping () -> ()) {
        
        asyncAfter(deadline: .now() + delay, execute: closure)
    }
    
    /// 创建GCD timer
    func timer(flags: DispatchSource.TimerFlags = [],
                      deadline: DispatchTime = .now(),
                      interval: DispatchTimeInterval,
                      leeway: DispatchTimeInterval = .milliseconds(1),
                      repeat: Bool = true, handler: @escaping @convention(block) () -> ()) -> DispatchSourceTimer {
        
        let timer = DispatchSource.makeTimerSource(flags: flags, queue: self)
        
        timer.setEventHandler(handler: handler)
        
        if `repeat` {
            timer.schedule(deadline: deadline, repeating: interval, leeway: leeway)
        } else {
            timer.schedule(deadline: deadline, leeway: leeway)
        }
        
        return timer
    }
}


/// 给resume 和 cancel 起个别名 便于 阅读
public extension DispatchSourceTimer {
    
    func start() {
        self.resume()
    }
    
    func stop() {
        self.cancel()
    }
}
