import SwiftUI
import SwiftData
import PlainCore

struct TagManagerView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Tag.createdAt) private var tags: [Tag]
    @State private var isAddingNew = false
    @State private var newTagName = ""
    @State private var newTagColorIndex = 5
    @State private var editingTag: Tag? = nil
    @State private var editName = ""
    @State private var editColorIndex = 0
    @State private var tagToDelete: Tag? = nil

    private var store: TodoStore { TodoStore(container: context.container) }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("タグ管理")
                    .font(.headline)
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .font(.title3)
                }
                .buttonStyle(.plain)
            }
            .padding(16)

            Divider()

            // Tag list
            if tags.isEmpty && !isAddingNew {
                VStack(spacing: 12) {
                    Image(systemName: "tag")
                        .font(.system(size: 32))
                        .foregroundStyle(.tertiary)
                    Text("タグがありません")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(tags) { tag in
                            tagRow(tag)
                            Divider().padding(.horizontal, 16)
                        }
                    }
                }
            }

            Divider()

            // Add new tag
            if isAddingNew {
                newTagForm
            } else {
                Button {
                    isAddingNew = true
                    newTagName = ""
                    newTagColorIndex = 5
                } label: {
                    Label("新規タグ", systemImage: "plus")
                        .font(.callout)
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color.accentColor)
                .padding(12)
            }
        }
        .frame(width: 400, height: 480)
        .background(Color(red: 249/255, green: 249/255, blue: 255/255))
        .alert("タグを削除", isPresented: Binding(
            get: { tagToDelete != nil },
            set: { if !$0 { tagToDelete = nil } }
        )) {
            Button("キャンセル", role: .cancel) { tagToDelete = nil }
            Button("削除", role: .destructive) {
                if let tag = tagToDelete {
                    store.deleteTag(tag)
                    tagToDelete = nil
                }
            }
        } message: {
            if let tag = tagToDelete {
                Text("タグ「\(tag.name)」を削除します。タスクからタグが外れますが、タスクは削除されません。")
            }
        }
        .sheet(item: $editingTag) { tag in
            editTagSheet(tag)
        }
    }

    // MARK: - Tag row

    private func tagRow(_ tag: Tag) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(TagColor.from(index: tag.colorIndex).foregroundColor)
                .frame(width: 10, height: 10)
            Text(tag.name)
                .font(.callout)
            Text("\(tag.items.count)件")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Button { editingTag = tag; editName = tag.name; editColorIndex = tag.colorIndex } label: {
                Image(systemName: "pencil")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            Button { tagToDelete = tag } label: {
                Image(systemName: "trash")
                    .font(.caption)
                    .foregroundStyle(.red.opacity(0.7))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // MARK: - New tag form

    private var newTagForm: some View {
        VStack(spacing: 12) {
            HStack {
                TextField("タグ名", text: $newTagName)
                    .textFieldStyle(.plain)
                    .font(.callout)
                    .padding(8)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            colorGrid(selection: $newTagColorIndex)
            HStack {
                Button("キャンセル") {
                    isAddingNew = false
                }
                .buttonStyle(.bordered)
                Button("追加") {
                    let trimmed = newTagName.trimmingCharacters(in: .whitespaces)
                    guard !trimmed.isEmpty else { return }
                    store.addTag(name: trimmed, colorIndex: newTagColorIndex)
                    isAddingNew = false
                }
                .buttonStyle(.borderedProminent)
                .disabled(newTagName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(12)
    }

    // MARK: - Edit tag sheet

    private func editTagSheet(_ tag: Tag) -> some View {
        VStack(spacing: 16) {
            Text("タグを編集")
                .font(.headline)
            TextField("タグ名", text: $editName)
                .textFieldStyle(.roundedBorder)
            colorGrid(selection: $editColorIndex)
            HStack {
                Spacer()
                Button("キャンセル") { editingTag = nil }
                    .buttonStyle(.bordered)
                Button("保存") {
                    let trimmed = editName.trimmingCharacters(in: .whitespaces)
                    guard !trimmed.isEmpty else { return }
                    store.updateTag(tag, name: trimmed, colorIndex: editColorIndex)
                    editingTag = nil
                }
                .buttonStyle(.borderedProminent)
                .disabled(editName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(24)
        .frame(width: 320)
    }

    // MARK: - Color grid

    private func colorGrid(selection: Binding<Int>) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.fixed(28), spacing: 8), count: 6), spacing: 8) {
            ForEach(TagColor.allCases, id: \.rawValue) { color in
                Circle()
                    .fill(color.foregroundColor)
                    .frame(width: 24, height: 24)
                    .overlay {
                        if selection.wrappedValue == color.rawValue {
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                    .onTapGesture {
                        selection.wrappedValue = color.rawValue
                    }
            }
        }
    }
}



