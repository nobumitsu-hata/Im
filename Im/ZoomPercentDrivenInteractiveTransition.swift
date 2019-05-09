//
//  ZoomPercentDrivenInteractiveTransition.swift
//  Im
//
//  Created by nobumitsu on 2019/05/01.
//  Copyright © 2019 im. All rights reserved.
//

import UIKit

// 画面遷移のメソッドを実行するための Delegate
protocol ZoomPercentDrivenInteractiveTransitionDelegate: class {
    func zoomPercentDrivenInteractiveTransitionScreenEdgePanBegan()
}

class ZoomPercentDrivenInteractiveTransition: UIPercentDrivenInteractiveTransition {
    weak var delegate: ZoomPercentDrivenInteractiveTransitionDelegate?
    
    // UINavigationController の Delegate メソッドで
    // インタラクティブかどうかを判断する必要があるのでフラグを持つ
    var isInteractive = false
    
    // このメソッドをビューに追加したエッジパンジェスチャのハンドラとして登録しておく
    func handle(screenEdgePanGestureRecognizer: UIScreenEdgePanGestureRecognizer) {
        guard let view = screenEdgePanGestureRecognizer.view else {
            return
        }
        
        switch screenEdgePanGestureRecognizer.state {
        case .began:
            // ジェスチャが開始したタイミングで一度だけこのスコープに入る
            // delegate で VC の push メソッドを実行して画面遷移を開始する
            delegate?.zoomPercentDrivenInteractiveTransitionScreenEdgePanBegan()
        case .changed:
            // 画面サイズとスワイプの移動量から進捗を計算する
            let progress = screenEdgePanGestureRecognizer.translation(in: view).x / view.bounds.width
            
            // update に進捗を渡すだけでアニメーションが進捗に合わせて変化する
            update(progress)
        case .cancelled, .ended:
            let progress = screenEdgePanGestureRecognizer.translation(in: view).x / view.bounds.width
            let velocity = screenEdgePanGestureRecognizer.velocity(in: view).x
            
            // 画面から指が離れたタイミングでのスワイプの量と速度を見て
            // 画面遷移を完了させるか中断させるかを判断する
            if velocity < 0.0 || progress < 0.1 {
                // cancel を呼ぶと画面遷移が中断されて元の画面が表示される
                cancel()
            } else {
                // finish を呼ぶと画面遷移が最後まで行われる
                finish()
            }
        case .possible, .failed:
            break
        }
    }
}
