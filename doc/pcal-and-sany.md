
https://github.com/tlaplus/vscode-tlaplus/wiki/Visualizing-States

TLC model checker can dump generated states to a file in DOT notation. Such .dot files can be visualized as graphs right in VS Code with the help of additional extensions. Here're the most popular of them:

https://www.graphviz.org/doc/info/lang.html
Graphviz Interactive Preview,
Graphviz Preview,
Graphviz (dot) language support for Visual Studio Code.
To generate .dot files while running model checking, add -dump dot file_name.dot TLC option in the extension settings. Setting variables usually come handy here — one can provide -dump dot ${modelName}.dot as a TLC option to automatically generate the resulting .dot file name based on the model being checked.

@@@@@@@@@@@@@@@@
TLA+: Parse module command for both translating a PlusCal algorithm to TLA+ code and parsing the resulting TLA+ module.

SANY (the TLA+ parser) parses and checks native TLA+, not PlusCal. PlusCal lives inside a TLA+ comment, so SANY ignores it entirely.

The flow:

pcal.trans (the PlusCal translator) reads the (*--algorithm ... *) comment, parses the PlusCal, and writes generated TLA+ back into the file between \* BEGIN TRANSLATION / \* END TRANSLATION markers. This is the only tool that understands PlusCal syntax.

SANY then parses the whole .tla file as native TLA+: syntax check + semantic analysis (name resolution, arity, level checking). It never sees the PlusCal.

@@@@@@@@@@@
https://github.com/tlaplus/vscode-tlaplus/wiki/Caveats
