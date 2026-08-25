#!/usr/bin/env python3
"""Generate the drawn plates used in README.md and docs/FRAMEWORK.md.

Writes EVERY theme variant of EVERY plate from one shared palette, so the plates
cannot drift apart from each other or from their own light/dark twin:
    python3 docs/img/gen-plates.py

Output (next to this file):
    workspace-layer-{light,dark}.svg   state one level above the repos
    review-pipeline-{light,dark}.svg   author -> reviewer -> gate -> commit

Editing: change MEM / REPOS below and re-run. The column grid is derived from
how many entries each list has, so adding a card re-spaces the row instead of
dropping it. No <style> blocks or external refs on purpose — GitHub's markdown
sanitizer strips those, and every attribute here has to survive it.
"""

SERIF = "Iowan Old Style, Palatino, Georgia, Times New Roman, serif"
MONO = "ui-monospace, SFMono-Regular, SF Mono, Menlo, Consolas, Liberation Mono, monospace"

W, H = 880, 540

# ---- palettes -------------------------------------------------------------
DARK = dict(
    ground="#0F0E11",
    frame="#C9A84C", frame_op="0.45",
    hair="#C9A84C",
    band="#1F1A11",          # warm slab under the memory row
    card="#221D14",
    card_stroke="#C9A84C", card_stroke_op="0.55",
    fold="#2E2718",
    file_ink="#E8DCC0",      # mono filenames on memory cards
    file_gloss="#A79B84",
    gold_text="#C9A84C",     # gold is safe AS TEXT only on the dark ground
    gold_soft="#B9A87A",
    ink="#E8DCC0",
    repo_fill="#151519",
    repo_stroke="#3F3F49",
    repo_ink="#C4C4CC",
    repo_gloss="#8B8B96",
    repo_label="#93939E",
    chip_fill="#1D1D23",
    ghost_stroke="#33333C",
    ghost_ink="#84848F",
)

LIGHT = dict(
    ground="#FDFCFA",
    frame="#C9A84C", frame_op="0.65",
    hair="#C9A84C",
    band="#FAF5E9",
    card="#FFFDF7",
    card_stroke="#C9A84C", card_stroke_op="0.75",
    fold="#F0E6CC",
    file_ink="#2A241A",
    file_gloss="#6E6350",
    gold_text="#8A6A1E",     # gold DARKENED for text; #C9A84C on paper is ~2.2:1
    gold_soft="#7A6428",
    ink="#1F1F24",
    repo_fill="#F4F4F6",
    repo_stroke="#C3C3CC",
    repo_ink="#2C2C33",
    repo_gloss="#63636D",
    repo_label="#5E5E68",
    chip_fill="#EDEDF1",
    ghost_stroke="#CFCFD7",
    ghost_ink="#70707A",
)


def esc(s):
    return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")


def txt(x, y, s, *, size, fill, family=SERIF, weight=None, style=None,
        anchor=None, ls=None, op=None):
    a = [f'x="{x}"', f'y="{y}"', f'font-family="{family}"',
         f'font-size="{size}"', f'fill="{fill}"']
    if weight:
        a.append(f'font-weight="{weight}"')
    if style:
        a.append(f'font-style="{style}"')
    if anchor:
        a.append(f'text-anchor="{anchor}"')
    if ls:
        a.append(f'letter-spacing="{ls}"')
    if op:
        a.append(f'fill-opacity="{op}"')
    return f'<text {" ".join(a)}>{esc(s)}</text>'


def line(x1, y1, x2, y2, stroke, w=1, op=None, dash=None):
    a = [f'x1="{x1}"', f'y1="{y1}"', f'x2="{x2}"', f'y2="{y2}"',
         f'stroke="{stroke}"', f'stroke-width="{w}"']
    if op:
        a.append(f'stroke-opacity="{op}"')
    if dash:
        a.append(f'stroke-dasharray="{dash}"')
    return f'<line {" ".join(a)}/>'


def rect(x, y, w, h, *, fill="none", stroke=None, sw=1, rx=None,
         sop=None, fop=None, dash=None):
    a = [f'x="{x}"', f'y="{y}"', f'width="{w}"', f'height="{h}"', f'fill="{fill}"']
    if stroke:
        a += [f'stroke="{stroke}"', f'stroke-width="{sw}"']
    if rx is not None:
        a.append(f'rx="{rx}"')
    if sop:
        a.append(f'stroke-opacity="{sop}"')
    if fop:
        a.append(f'fill-opacity="{fop}"')
    if dash:
        a.append(f'stroke-dasharray="{dash}"')
    return f'<rect {" ".join(a)}/>'


def hatch(x, y, w, h, stroke, step=7, op="0.9"):
    """45-degree hatching inside a rect, clipped to it by arithmetic so the
    SVG needs no <defs>/<clipPath> (fewer moving parts for the sanitizer)."""
    out = [rect(x, y, w, h, fill="none", stroke=stroke, sw=1.2)]
    yy = y
    while yy <= y + h + w:
        x0, y0 = x, min(yy, y + h)          # start on left or bottom edge
        if yy > y + h:
            x0 = x + (yy - (y + h))
        x1, y1 = x + w, yy - w              # end on right or top edge
        if y1 < y:
            x1, y1 = x + (yy - y), y
        if x1 > x0:
            out.append(line(round(x0, 1), round(y0, 1), round(x1, 1),
                            round(y1, 1), stroke, 1, op=op))
        yy += step
    return "\n".join(out)


# ---- shared geometry ------------------------------------------------------
FX, FY, FW, FH = 28, 76, 824, 438          # outer frame = org-workspace/
FR = FX + FW                                # 852
HDR = 112                                   # header strip bottom
BAND_T, BAND_B = 112, 280                   # memory slab
CARD_Y, CARD_H = 154, 104
DIV_Y = 306
REPO_LBL = 336
RY, RH = 352, 144
# Column grid is DERIVED, never hardcoded: add a fifth memory file and the
# columns re-space themselves instead of silently dropping it.
GRID_L, GRID_R = 48, 832                    # usable band, inside the frame
COL_GAP = 16


def _grid(n):
    """n evenly spaced columns across [GRID_L, GRID_R] -> (positions, width)."""
    span = GRID_R - GRID_L
    w = (span - COL_GAP * (n - 1)) / n
    return [GRID_L + i * (w + COL_GAP) for i in range(n)], w

MEM = [
    ("INDEX.md",        "the map: every repo,", "what it is, its stack"),
    ("STATUS.md",       "where we are and",     "what happens next"),
    ("DECISIONS.md",    "cross-repo choices",   "and their why"),
    (".claude/todos.md", "one focus list, each", "task tagged by repo"),
]
REPOS = ["service-api/", "web-front/", "data-jobs/"]


def build_workspace(p):
    o = []
    A = o.append

    A(f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" '
      f'width="{W}" height="{H}" role="img" '
      f'aria-labelledby="wl-title wl-desc">')
    A('<title id="wl-title">The workspace layer</title>')
    A('<desc id="wl-desc">A section through org-workspace: the Claude Code '
      'session opens at the top, in a plain folder with no .git. Inside it, a '
      'warm band of workspace memory files sits above a row of ordinary, '
      'untouched git repos, each keeping its own .claude/ state. Nothing '
      'connects the two bands: no submodules, no workspace build, no '
      'lockfile.</desc>')

    # page ground
    A(rect(0, 0, W, H, fill=p["ground"]))

    # ---------- ingress: the session enters at the top ----------
    A(f'<text x="48" y="34" font-family="{MONO}" font-size="15">'
      f'<tspan fill="{p["gold_text"]}">$</tspan>'
      f'<tspan fill="{p["ink"]}" dx="9">claude</tspan></text>')
    A(rect(126, 22, 8, 15, fill=p["gold_text"], fop="0.75"))
    A(txt(162, 34, "the session opens here, one level above every repo",
          size=13, fill=p["gold_soft"], style="italic"))
    A(txt(FR - 20, 34, "not a monorepo  ·  not a meta-repo", size=10.5,
          fill=p["repo_label"], family=MONO, anchor="end"))
    A(line(52, 46, 52, 66, p["hair"], 1.2, op="0.8"))
    A(f'<path d="M 46 64 L 58 64 L 52 74 Z" fill="{p["hair"]}" '
      f'fill-opacity="0.85"/>')

    # ---------- the folder ----------
    A(rect(FX, FY, FW, FH, fill="none", stroke=p["frame"], sw=1.25,
           sop=p["frame_op"]))

    # header strip
    A(txt(48, 101, "org-workspace/", size=17, fill=p["ink"], family=MONO,
          weight="500"))
    A(txt(206, 101, "a plain folder", size=12.5, fill=p["repo_gloss"],
          style="italic"))
    # chip: no .git   (rhymes with the .git chips on every repo below)
    A(rect(FR - 86, 87, 66, 20, fill="none", stroke=p["hair"], sw=1, rx=3,
           sop="0.6"))
    A(txt(FR - 53, 101, "no .git", size=10.5, fill=p["gold_text"],
          family=MONO, anchor="middle"))
    A(line(FX, HDR, FR, HDR, p["hair"], 1, op="0.3"))

    # ---------- band 1: workspace memory ----------
    A(rect(FX + 1, BAND_T, FW - 2, BAND_B - BAND_T, fill=p["band"]))
    A(line(FX, BAND_B, FR, BAND_B, p["hair"], 1, op="0.22"))

    A(txt(48, 140, "WORKSPACE MEMORY", size=11, fill=p["gold_text"],
          weight="600", ls="1.7"))
    A(txt(214, 140, "state no single repo could own", size=12,
          fill=p["file_gloss"], style="italic"))
    A(txt(FR - 20, 140, "the layer holds memory", size=12,
          fill=p["gold_soft"], style="italic", anchor="end"))

    mem_x, mem_w = _grid(len(MEM))
    repo_x, repo_w = _grid(len(REPOS) + 1)   # +1 slot for the ghost card

    for (name, g1, g2), x in zip(MEM, mem_x):
        cx, cy, cw, ch = x, CARD_Y, mem_w, CARD_H
        # dog-eared page
        A(f'<path d="M {cx} {cy} L {cx+cw-15} {cy} L {cx+cw} {cy+15} '
          f'L {cx+cw} {cy+ch} L {cx} {cy+ch} Z" fill="{p["card"]}" '
          f'stroke="{p["card_stroke"]}" stroke-width="1" '
          f'stroke-opacity="{p["card_stroke_op"]}"/>')
        A(f'<path d="M {cx+cw-15} {cy} L {cx+cw-15} {cy+15} L {cx+cw} {cy+15} Z" '
          f'fill="{p["fold"]}" stroke="{p["card_stroke"]}" stroke-width="1" '
          f'stroke-opacity="{p["card_stroke_op"]}"/>')
        A(txt(cx + 15, cy + 32, name, size=14, fill=p["file_ink"], family=MONO))
        A(line(cx + 15, cy + 43, cx + 51, cy + 43, p["hair"], 1.4, op="0.85"))
        A(txt(cx + 15, cy + 64, g1, size=12, fill=p["file_gloss"]))
        A(txt(cx + 15, cy + 81, g2, size=12, fill=p["file_gloss"]))

    # ---------- the boundary ----------
    mid = 440
    # Rules stop 20px clear of the text box (52 chars at 10.5px mono ~= 330px,
    # so the label spans roughly 275..605 around the midpoint).
    A(line(48, DIV_Y, 255, DIV_Y, p["hair"], 1, op="0.55"))
    A(line(625, DIV_Y, 832, DIV_Y, p["hair"], 1, op="0.55"))
    A(txt(mid, DIV_Y + 4, "no submodules  ·  no workspace build  ·  no lockfile",
          size=10.5, fill=p["gold_text"], family=MONO, anchor="middle"))

    # ---------- band 2: ordinary git repos ----------
    A(txt(48, REPO_LBL, "ORDINARY GIT REPOS", size=11, fill=p["repo_label"],
          weight="600", ls="1.7"))
    A(txt(226, REPO_LBL, "untouched, unaware the layer exists", size=12,
          fill=p["repo_gloss"], style="italic"))
    A(txt(FR - 20, REPO_LBL, "the repos just hold code", size=12,
          fill=p["repo_gloss"], style="italic", anchor="end"))

    def folder(x, y, w, h, fill, stroke, dash=None):
        d = (f'M {x} {y} L {x+46} {y} L {x+57} {y+11} L {x+w} {y+11} '
             f'L {x+w} {y+h} L {x} {y+h} Z')
        extra = f' stroke-dasharray="{dash}"' if dash else ""
        return (f'<path d="{d}" fill="{fill}" stroke="{stroke}" '
                f'stroke-width="1"{extra}/>')

    for name, x in zip(REPOS, repo_x):
        A(folder(x, RY, repo_w, RH, p["repo_fill"], p["repo_stroke"]))
        A(txt(x + 16, RY + 38, name, size=14, fill=p["repo_ink"], family=MONO))
        # chip: .git   (same silhouette as the folder's "no .git" chip)
        A(rect(x + 16, RY + 48, 48, 18, fill=p["chip_fill"],
               stroke=p["repo_stroke"], sw=1, rx=3))
        A(txt(x + 40, RY + 61, ".git", size=10, fill=p["repo_gloss"],
              family=MONO, anchor="middle"))
        # its own per-repo state, sealed inside
        A(rect(x + 16, RY + 76, repo_w - 32, 56, fill="none",
               stroke=p["repo_stroke"], sw=1, dash="3 3"))
        A(txt(x + 30, RY + 95, ".claude/", size=11, fill=p["repo_ink"],
              family=MONO))
        A(txt(x + 30, RY + 110, "conventions,", size=10.5, fill=p["repo_gloss"]))
        A(txt(x + 30, RY + 124, "architecture, specs", size=10.5,
              fill=p["repo_gloss"]))

    gx = repo_x[len(REPOS)]          # the reserved trailing slot
    A(folder(gx, RY, repo_w, RH, "none", p["ghost_stroke"], dash="4 4"))
    A(txt(gx + repo_w / 2, RY + 66, "ten more repos", size=14,
          fill=p["ghost_ink"], style="italic", anchor="middle"))
    # No fill-opacity here: fading ghost_ink 15% into the light ground drops
    # this line to ~3.1:1, under AA. Full-strength ghost_ink is 4.9:1 / 5.1:1.
    A(txt(gx + repo_w / 2, RY + 94, "none of them modified", size=11.5,
          fill=p["ghost_ink"], anchor="middle"))

    A("</svg>")
    return "\n".join(o) + "\n"


# ===========================================================================
#  PLATE 2 — the commit pipeline: author, reviewer, gate
# ===========================================================================
# Same palette and same material logic as plate 1: warm = the agents that
# think, cool = the machine that does not. The teaching device here is the
# receipt — /code-review hashes the exact staged diff, the gate recomputes it,
# and the wall in band 2 has exactly one gap. A matching hash fits through it;
# anything staged after the review does not.

P2W, P2H = 880, 470
P2FX, P2FY, P2FW, P2FH = 28, 76, 824, 362
P2FR = P2FX + P2FW
P2HDR = 112
B2_T = 292                                  # band 2 (the receipt) starts here

ACTORS = [
    # (name, role, line, chip_a, chip_b, machine?)
    ("/work", "AUTHOR", "the session that writes",
     "holds the pen", "spec -> .claude/specs/", False),
    ("code-reviewer", "REVIEWER", "a subagent, not this session",
     "clean context", "no write tools", False),
    ("commit-gate.sh", "GATE", "a PreToolUse hook",
     "code, not a prompt", "runs every single time", True),
]


def build_pipeline(p):
    o = []
    A = o.append

    A(f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {P2W} {P2H}" '
      f'width="{P2W}" height="{P2H}" role="img" '
      f'aria-labelledby="rp-title rp-desc">')
    A('<title id="rp-title">The commit pipeline</title>')
    A('<desc id="rp-desc">Three actors with different powers. /work is the '
      'author and holds the pen. code-reviewer is a separate subagent with a '
      'clean context and no write tools. commit-gate.sh is a PreToolUse hook: '
      'code, not a prompt. The reviewer writes a receipt containing a hash of '
      'the exact staged diff; the gate recomputes that hash at commit time. A '
      'matching hash passes through the gate and the commit lands. If anything '
      'was staged after the review the hash no longer matches and the commit '
      'is blocked.</desc>')

    A(rect(0, 0, P2W, P2H, fill=p["ground"]))

    # ---------- top annotation, mirroring plate 1 ----------
    A(f'<text x="48" y="34" font-family="{MONO}" font-size="15">'
      f'<tspan fill="{p["gold_text"]}">$</tspan>'
      f'<tspan fill="{p["ink"]}" dx="9">git commit</tspan></text>')
    A(txt(196, 34, "three actors, and only one of them holds the pen",
          size=13, fill=p["gold_soft"], style="italic"))
    A(txt(P2FR - 20, 34, "a prompt is a request  ·  a hook is a wall",
          size=10.5, fill=p["repo_label"], family=MONO, anchor="end"))

    # ---------- the frame ----------
    A(rect(P2FX, P2FY, P2FW, P2FH, fill="none", stroke=p["frame"], sw=1.25,
           sop=p["frame_op"]))

    A(txt(48, 101, "separation of powers", size=17, fill=p["ink"],
          family=MONO, weight="500"))
    A(txt(282, 101, "author, reviewer and gate are different actors",
          size=12.5, fill=p["repo_gloss"], style="italic"))
    # chip: no --no-verify   (rhymes with plate 1's "no .git")
    A(rect(P2FR - 128, 87, 108, 20, fill="none", stroke=p["hair"], sw=1, rx=3,
           sop="0.6"))
    A(txt(P2FR - 74, 101, "no --no-verify", size=10.5, fill=p["gold_text"],
          family=MONO, anchor="middle"))
    A(line(P2FX, P2HDR, P2FR, P2HDR, p["hair"], 1, op="0.3"))

    # ---------- band 1: the three actors ----------
    A(rect(P2FX + 1, P2HDR, P2FW - 2, B2_T - P2HDR, fill=p["band"]))
    A(line(P2FX, B2_T, P2FR, B2_T, p["hair"], 1, op="0.22"))

    ax, aw = _grid(len(ACTORS))
    CY, CH = 146, 118

    for (name, role, sub, chip_a, chip_b, machine), x in zip(ACTORS, ax):
        if machine:
            # steel: sharp corners, cool palette, a doubled left edge so it
            # reads as a barrier rather than a card that thinks.
            A(rect(x, CY, aw, CH, fill=p["repo_fill"], stroke=p["repo_stroke"],
                   sw=1))
            A(line(x + 5, CY + 6, x + 5, CY + CH - 6, p["repo_stroke"], 1))
            ink, gloss, label = p["repo_ink"], p["repo_gloss"], p["repo_label"]
            chip_stroke = p["repo_stroke"]
        else:
            # warm agent card, same dog-eared page as plate 1's memory files
            A(f'<path d="M {x} {CY} L {x+aw-15} {CY} L {x+aw} {CY+15} '
              f'L {x+aw} {CY+CH} L {x} {CY+CH} Z" fill="{p["card"]}" '
              f'stroke="{p["card_stroke"]}" stroke-width="1" '
              f'stroke-opacity="{p["card_stroke_op"]}"/>')
            A(f'<path d="M {x+aw-15} {CY} L {x+aw} {CY+15} L {x+aw-15} {CY+15} Z" '
              f'fill="{p["fold"]}"/>')
            ink, gloss, label = p["file_ink"], p["file_gloss"], p["gold_text"]
            chip_stroke = p["card_stroke"]

        A(txt(x + 16, CY + 30, role, size=9.5, fill=label, weight="600",
              ls="1.6"))
        A(txt(x + 16, CY + 54, name, size=15, fill=ink, family=MONO))
        A(txt(x + 16, CY + 72, sub, size=11, fill=gloss, style="italic"))
        for i, c in enumerate((chip_a, chip_b)):
            cy = CY + 86 + i * 22
            A(rect(x + 16, cy, aw - 32, 18, fill=p["chip_fill"],
                   stroke=chip_stroke, sw=1, rx=3, sop="0.5"))
            A(txt(x + 26, cy + 13, c, size=10, fill=gloss, family=MONO))

    # hand-off arrows between the stations
    for i in range(len(ACTORS) - 1):
        x0 = ax[i] + aw + 3
        x1 = ax[i + 1] - 3
        midy = CY + CH / 2
        A(line(x0, midy, x1 - 7, midy, p["hair"], 1.2, op="0.75"))
        A(f'<path d="M {x1-8} {midy-5} L {x1} {midy} L {x1-8} {midy+5} Z" '
          f'fill="{p["hair"]}" fill-opacity="0.85"/>')

    # ---------- band 2: the receipt, and the one gap in the wall ----------
    A(txt(48, 320, "THE RECEIPT", size=11, fill=p["gold_text"],
          weight="600", ls="1.7"))
    A(txt(158, 320, "a hash of the exact staged diff, recomputed at "
          "commit time", size=12, fill=p["file_gloss"], style="italic"))

    WALL_X, WALL_W = 566, 14
    WALL_T, WALL_B = 300, 436
    PASS_Y, GAP_H = 372, 32       # the corridor: the only way through
    STOP_Y = 410
    gap_t, gap_b = PASS_Y - GAP_H / 2, PASS_Y + GAP_H / 2

    A(txt(WALL_X + WALL_W + 14, 316, "commit-gate.sh", size=9.5,
          fill=p["repo_label"], family=MONO))
    # solid material, hatched, in two pieces with exactly one opening
    A(hatch(WALL_X, WALL_T, WALL_W, gap_t - WALL_T, p["repo_stroke"]))
    A(hatch(WALL_X, gap_b, WALL_W, WALL_B - gap_b, p["repo_stroke"]))
    # the jambs: heavier lips so the gap reads as a doorway, not a break
    for yy in (gap_t, gap_b):
        A(line(WALL_X - 4, yy, WALL_X + WALL_W + 4, yy, p["repo_stroke"], 2))

    # lane 1 — the hash still matches, so it fits through the gap
    A(txt(186, PASS_Y + 4, "reviewed", size=11.5, fill=p["gold_soft"],
          style="italic", anchor="end"))
    A(rect(198, PASS_Y - 11, 76, 22, fill=p["chip_fill"], stroke=p["hair"],
           sw=1, rx=3, sop="0.7"))
    A(txt(236, PASS_Y + 4, "a3f9 ...", size=11, fill=p["gold_text"],
          family=MONO, anchor="middle"))
    A(line(278, PASS_Y, 700, PASS_Y, p["hair"], 1.5, op="0.9"))
    A(f'<path d="M 700 {PASS_Y-5.5} L 711 {PASS_Y} L 700 {PASS_Y+5.5} Z" '
      f'fill="{p["hair"]}"/>')
    A(txt(722, PASS_Y + 5, "git commit", size=13.5, fill=p["ink"], family=MONO))

    # lane 2 — staged after the review, so a different hash meets solid wall
    A(txt(186, STOP_Y + 4, "staged after", size=11.5, fill=p["ghost_ink"],
          style="italic", anchor="end"))
    A(rect(198, STOP_Y - 11, 76, 22, fill=p["chip_fill"],
           stroke=p["ghost_stroke"], sw=1, rx=3))
    A(txt(236, STOP_Y + 4, "7c21 ...", size=11, fill=p["ghost_ink"],
          family=MONO, anchor="middle"))
    A(line(278, STOP_Y, WALL_X - 13, STOP_Y, p["ghost_stroke"], 1.5, dash="5 4"))
    # it arrives, and stops dead against the face of the wall
    A(rect(WALL_X - 13, STOP_Y - 9, 9, 18, fill=p["ghost_stroke"]))
    A(txt(WALL_X + WALL_W + 14, STOP_Y + 5, "blocked  ·  review again, then commit",
          size=11.5, fill=p["repo_gloss"], style="italic"))

    A("</svg>")
    return "\n".join(o) + "\n"


if __name__ == "__main__":
    import sys
    out = sys.argv[1] if len(sys.argv) > 1 else "."
    plates = (("workspace-layer", build_workspace),
              ("review-pipeline", build_pipeline))
    for stem, fn in plates:
        for name, pal in (("light", LIGHT), ("dark", DARK)):
            path = f"{out}/{stem}-{name}.svg"
            with open(path, "w") as f:
                f.write(fn(pal))
            print("wrote", path)
