#!/usr/bin/env python3
"""
step-through: One-at-a-time decision TUI for Claude agent workflows.

Input  (stdin or --input FILE): JSON array of decision items
Output (stdout or --output FILE): JSON array of confirmed items

Item schema:
  {
    "uuid":           str,   # required - item identifier
    "original_title": str,   # required - raw input as captured
    "title":          str,   # required - proposed (rephrased) title
    "project":        str,   # required - proposed project name
    "when":           str,   # "anytime" | "today" | "someday" | "YYYY-MM-DD"
    "deadline":       str?,  # "YYYY-MM-DD" or null
    "notes":          str?   # optional context shown to user
  }

Output adds:
  "action": "accept" | "skip"
  (title, project, when, deadline may have been modified by user)
"""

import json
import sys
import os
import argparse

from rich.console import Console
import questionary
from questionary import Style

console = Console()

STYLE = Style([
    ("qmark",       "fg:#5f87ff bold"),
    ("question",    "bold"),
    ("answer",      "fg:#5f87ff bold"),
    ("pointer",     "fg:#5f87ff bold"),
    ("highlighted", "fg:#5f87ff bold"),
    ("selected",    "fg:#5f87ff"),
    ("separator",   "fg:#6c6c6c"),
    ("instruction", "fg:#6c6c6c"),
])


def refine_with_claude(original_title, current_title, user_prompt):
    """Call Claude via Bedrock to refine a title based on user's description."""
    try:
        import anthropic
        client = anthropic.AnthropicBedrock(aws_region="us-west-2")
        message = client.messages.create(
            model="us.anthropic.claude-sonnet-4-6",
            max_tokens=200,
            messages=[{
                "role": "user",
                "content": (
                    f"Refine this task title based on the user's request.\n\n"
                    f"Original raw text: {original_title}\n"
                    f"Current proposed title: {current_title}\n"
                    f"User's request: {user_prompt}\n\n"
                    f"Return ONLY the new title. Include emoji prefix if appropriate. "
                    f"No explanation, no quotes."
                ),
            }],
        )
        return message.content[0].text.strip()
    except Exception as e:
        console.print(f"[red]Refinement failed: {e}[/red]")
        return current_title


def display_item(item, index, total):
    console.clear()
    console.print(f"\n[dim] Item {index + 1} / {total}[/dim]")
    console.print("─" * 52)
    console.print(f"[dim] Original :[/dim]  {item['original_title']}")
    console.print()
    console.print(f"[bold] Title   →[/bold]  {item['title']}")
    console.print(f"[bold] Project →[/bold]  {item['project']}")
    console.print(f"[bold] When    →[/bold]  {item.get('when', 'anytime')}")
    if item.get("deadline"):
        console.print(f"[bold] Due     →[/bold]  {item['deadline']}")
    if item.get("notes"):
        console.print(f"\n[dim] {item['notes']}[/dim]")
    console.print()


def process_item(item, index, total):
    """Interactively process one item. Returns item with action set, or None on abort."""
    current = item.copy()

    while True:
        display_item(current, index, total)

        choice = questionary.rawselect(
            "Action:",
            choices=[
                questionary.Choice("Accept", shortcut_key="1"),
                questionary.Choice("Edit title directly", shortcut_key="2"),
                questionary.Choice("Refine title with prompt", shortcut_key="3"),
                questionary.Choice("Change routing", shortcut_key="4"),
                questionary.Choice("Skip (leave in inbox)", shortcut_key="5"),
            ],
            style=STYLE,
        ).ask()

        if choice is None:  # Ctrl+C
            return None

        if choice == "Accept":
            current["action"] = "accept"
            return current

        elif choice == "Skip (leave in inbox)":
            current["action"] = "skip"
            return current

        elif choice == "Edit title directly":
            new_title = questionary.text(
                "Title:",
                default=current["title"],
                style=STYLE,
            ).ask()
            if new_title and new_title.strip():
                current["title"] = new_title.strip()

        elif choice == "Refine title with prompt":
            user_prompt = questionary.text(
                "Describe what you want →",
                style=STYLE,
            ).ask()
            if user_prompt and user_prompt.strip():
                console.print("\n[dim]Refining...[/dim]")
                current["title"] = refine_with_claude(
                    current["original_title"],
                    current["title"],
                    user_prompt.strip(),
                )

        elif choice == "Change routing":
            new_project = questionary.text(
                "Project:",
                default=current["project"],
                style=STYLE,
            ).ask()
            if new_project and new_project.strip():
                current["project"] = new_project.strip()

            new_when = questionary.rawselect(
                "When:",
                choices=[
                    questionary.Choice("anytime", shortcut_key="1"),
                    questionary.Choice("today",   shortcut_key="2"),
                    questionary.Choice("someday", shortcut_key="3"),
                ],
                style=STYLE,
            ).ask()
            if new_when:
                current["when"] = new_when

            new_deadline = questionary.text(
                "Deadline (YYYY-MM-DD or blank):",
                default=current.get("deadline") or "",
                style=STYLE,
            ).ask()
            current["deadline"] = new_deadline.strip() if new_deadline and new_deadline.strip() else None


def main():
    parser = argparse.ArgumentParser(description="Step-through decision TUI")
    parser.add_argument("--input",  "-i", help="Input JSON file (default: stdin)")
    parser.add_argument("--output", "-o", help="Output JSON file (default: stdout)")
    args = parser.parse_args()

    if args.input:
        with open(args.input) as f:
            items = json.load(f)
    else:
        items = json.load(sys.stdin)

    results = []
    for i, item in enumerate(items):
        result = process_item(item, i, len(items))
        if result is None:
            console.print("\n[yellow]Aborted.[/yellow]")
            sys.exit(1)
        results.append(result)

    accepted = sum(1 for r in results if r.get("action") == "accept")
    skipped  = sum(1 for r in results if r.get("action") == "skip")
    console.clear()
    console.print(f"\n[green]Done — {accepted} accepted[/green]  [dim]{skipped} skipped[/dim]\n")

    output_data = json.dumps(results, ensure_ascii=False, indent=2)
    if args.output:
        with open(args.output, "w") as f:
            f.write(output_data)
    else:
        print(output_data)


if __name__ == "__main__":
    main()
