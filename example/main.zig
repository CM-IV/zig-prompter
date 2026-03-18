const std = @import("std");
const Prompter = @import("prompter");

// Example of a simple string validator
fn len_three_val(str: []const u8) bool {
    return str.len == 3;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const check = gpa.deinit();
        if (check == .leak) @panic("The allocator has leaked!");
    }
    const allocator = gpa.allocator();

    var out_buf: [4096]u8 = undefined;
    var out_impl = std.fs.File.stdout().writer(&out_buf);
    const out = &out_impl.interface;

    // Initialize the Prompt struct with the simple theme
    const theme = Prompter.Themes.SimpleTheme{};
    var p = Prompter.Prompt.init(allocator, theme.theme());

    // Try out the option selection prompt
    {
        try out.writeAll("[ Option Selection Prompt ]\n");
        try out.flush();
        const opts = [_][]const u8{ "Option 1", "Option 2", "Option 3" };
        const sel_opt = try p.option("Select an option", &opts, 1);
        if (sel_opt) |o| {
            try out.print("\nThe selected option was: {s} (idx: {d})\n", .{ opts[o], o });
        } else {
            try out.writeAll("\nThe selection was aborted.\n");
        }
        try out.flush();
    }

    // Try out the string prompt
    {
        try out.writeAll("\n[ String Prompt ]\n");
        try out.flush();
        const input = try p.string("Write something", "Default");
        defer allocator.free(input);
        try out.print("The input was: {s}\n", .{input});
        try out.flush();
    }

    // Try out the string prompt with validation
    {
        try out.writeAll("\n[ Validated String Prompt ]\n");
        try out.flush();
        const input = try p.stringValidated("Write a string with length = 3", null, len_three_val);
        defer allocator.free(input);
        try out.print("The input was: {s}\n", .{input});
        try out.flush();
    }

    // Try out the confirmation prompt
    {
        try out.writeAll("\n[ Confirmation Prompt ]\n");
        try out.flush();
        const has_confirmed = try p.confirm("Please confirm or not [y/n]");
        if (has_confirmed) {
            try out.writeAll("The confirmation has a value of \"true\"\n");
        } else {
            try out.writeAll("The confirmation has a value of \"false\"\n");
        }
        try out.flush();
    }

    // Try out the password prompt
    {
        try out.writeAll("\n[ Password Prompt ]\n");
        try out.flush();
        var pass_buf: [64]u8 = undefined;
        const pass = try p.password("Insert a dummy password", &pass_buf);
        if (pass) |pw| {
            try out.print("The password inserted was: \"{s}\"\n", .{pw});
        } else {
            try out.writeAll("The insertion of the password was aborted.\n");
        }
        try out.flush();
    }
}
