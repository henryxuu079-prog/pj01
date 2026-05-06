import SwiftUI

struct AppCommands: Commands {
    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("新建旅行") {
                // TODO: 通过环境传递操作
            }
            .keyboardShortcut("n", modifiers: .command)
        }

        SidebarCommands()
    }
}
