//
//  AppRouter.swift
//  MyStory
//
//  应用路由管理器 - 统一管理页面导航
//

import SwiftUI

enum AppRoute: Hashable {
    case timeline
    case search(keyword: String? = nil)
    case storyDetail(storyId: UUID)
    case storyEditor(storyId: UUID? = nil)
    case locationPicker(currentLocation: LocationInfo? = nil)
    case categoryList
    case categoryDetail(categoryId: UUID)
    case settings
    case aiPolish(text: String)
    case dataSync
    
    // 实现Hashable协议
    func hash(into hasher: inout Hasher) {
        switch self {
        case .timeline:
            hasher.combine("timeline")
        case .search(let keyword):
            hasher.combine("search")
            hasher.combine(keyword)
        case .storyDetail(let id):
            hasher.combine("storyDetail")
            hasher.combine(id)
        case .storyEditor(let id):
            hasher.combine("storyEditor")
            hasher.combine(id)
        case .locationPicker:
            hasher.combine("locationPicker")
        case .categoryList:
            hasher.combine("categoryList")
        case .categoryDetail(let id):
            hasher.combine("categoryDetail")
            hasher.combine(id)
        case .settings:
            hasher.combine("settings")
        case .aiPolish(let text):
            hasher.combine("aiPolish")
            hasher.combine(text)
        case .dataSync:
            hasher.combine("dataSync")
        }
    }
    
    static func == (lhs: AppRoute, rhs: AppRoute) -> Bool {
        switch (lhs, rhs) {
        case (.timeline, .timeline):
            return true
        case (.search(let k1), .search(let k2)):
            return k1 == k2
        case (.storyDetail(let id1), .storyDetail(let id2)):
            return id1 == id2
        case (.storyEditor(let id1), .storyEditor(let id2)):
            return id1 == id2
        case (.locationPicker, .locationPicker):
            return true
        case (.categoryList, .categoryList):
            return true
        case (.categoryDetail(let id1), .categoryDetail(let id2)):
            return id1 == id2
        case (.settings, .settings):
            return true
        case (.aiPolish(let t1), .aiPolish(let t2)):
            return t1 == t2
        case (.dataSync, .dataSync):
            return true
        default:
            return false
        }
    }
}

class AppRouter: ObservableObject {
    @Published var path = NavigationPath()
    @Published var presentedSheet: AppRoute?
    @Published var presentedFullScreen: AppRoute?
    
    // 导航到指定路由
    func navigate(to route: AppRoute) {
        path.append(route)
    }
    
    // 返回上一页
    func navigateBack() {
        if !path.isEmpty {
            path.removeLast()
        }
    }
    
    // 返回根页面
    func navigateToRoot() {
        path.removeLast(path.count)
    }
    
    // 以Sheet方式展示
    func presentSheet(_ route: AppRoute) {
        presentedSheet = route
    }
    
    // 以全屏方式展示
    func presentFullScreen(_ route: AppRoute) {
        presentedFullScreen = route
    }
    
    // 关闭Sheet
    func dismissSheet() {
        presentedSheet = nil
    }
    
    // 关闭全屏
    func dismissFullScreen() {
        presentedFullScreen = nil
    }
}
