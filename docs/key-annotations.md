# Key Display Annotations

Override the SF Symbol(s) and/or label shown for any key using a `/* @key */` comment in your `.keymap` file.

## Syntax

```
/* @key icon:<sf-symbol>[,<sf-symbol>...] label:<text> */
```

Place the comment **immediately after** the binding it applies to, inside the `bindings = <...>` block.

Both `icon:` and `label:` are optional. If you use both, `label:` must come last (it captures the rest of the text, allowing spaces).

## Examples

Custom icon and label:
```dts
&macro_del_eol /* @key icon:delete.forward.fill label:Del to EOL */
```

Icon only (keeps the default label):
```dts
&macro_del_eol /* @key icon:delete.forward.fill */
```

Label only (keeps the default icon):
```dts
&macro_del_eol /* @key label:Del to EOL */
```

Multiple SF Symbols (comma-separated):
```dts
&macro_shift_del /* @key icon:shift,delete.forward.fill label:Shift Del */
```

In context:
```dts
bindings = <
    &kp Q  &kp W  &kp E  &kp R  &kp T    &macro_del_eol /* @key icon:delete.forward.fill label:Del EOL */
    &kp A  &kp S  &kp D  &kp F  &kp G    &kp H
    ...
>;
```

## Finding SF Symbol names

Browse available symbols in Apple's [SF Symbols](https://developer.apple.com/sf-symbols/) app. Use the symbol's API name (e.g. `delete.forward.fill`, `arrow.right.to.line`, `sun.max`).
