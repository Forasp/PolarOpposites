//
//  FileNodeView.swift
//  Giskard
//
//  Created by Timothy Powell on 7/16/25.
//

import SwiftUI

struct FileNodeView: View {
    @State private var expanded = false
    @Binding var levelsNested: Int
    @Binding var onSelectFolder: ((FileNodeView) -> Void)?
    var selected:Bool = false
    var node: FileNode

    var body: some View {
        if node.isDirectory
        {
            let indentedString = String(repeating: ">", count: levelsNested) + node.url.lastPathComponent
            Text(indentedString)
                .onTapGesture {
                    onSelectFolder!(self);
                }
                .background(selected ? Color.accentColor.opacity(0.25) : Color.clear)
            
            if (expanded)
            {
                if let children = node.children {
                    ForEach(children) { child in
                        FileNodeView(levelsNested: .constant(levelsNested+1), onSelectFolder: $onSelectFolder, node: child, )
                    }
                }
            }
        }
    }
    
    public mutating func setSelected(_ isSelected: Bool){
        if (selected && isSelected && expanded)
        {
            expanded = false;
        }
        else
        {
            expanded = true
        }
        
        selected = isSelected;
    }
    
}


#Preview {
    if let documentsNode = loadFileNode(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!) {
        FileNodeView(levelsNested: .constant(0), onSelectFolder:.constant(nil), node:documentsNode)
    }
}
