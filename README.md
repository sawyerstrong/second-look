# second-look

Rules and two reviewer agents that make Claude Code a more skeptical analysis partner. Claude states assumptions up front, flags gaps instead of filling them, and shows the calculations it ran. Two agents check your work before you submit it:

- **reviewer** audits a finished analysis and lists its problems, worst first.
- **devils-advocate** argues the strongest case against your conclusion.

second-look contains no domain knowledge. It checks whether your analysis supports your claims, never whether your answer is the "right" one.

When an assessment allows unlimited AI, using AI is not what sets you apart. Showing judgment about it is: which of its findings you acted on, which you overruled, and why. The review loop below is built to leave that record.

## 1. Prerequisites (10 minutes)

These steps are for a Chromebook. Claude Code runs inside ChromeOS's built-in Linux environment, not in the Chrome browser.

- A paid Claude plan (Pro or Max) or an Anthropic Console account.
- **Turn on Linux.** Open Settings, search for "Linux development environment," and click **Turn on**. Accept the defaults; setup takes a few minutes. When it finishes, a **Terminal** window opens. Every command below goes in that window.

  If the option is missing or grayed out, the Chromebook is managed by a school or employer that has disabled Linux. Claude Code will not run on it; use a different computer.

- **Copy and paste in Terminal** with **Ctrl+Shift+C** and **Ctrl+Shift+V**. Plain Ctrl+V does not paste there.

## 2. Install (5 minutes)

This installs second-look **globally**: the rules and agents apply to every Claude Code session in your Linux environment, in any folder. Section 5 explains how to remove it.

In Terminal:

```bash
sudo apt update && sudo apt install -y git
cd ~
git clone https://github.com/sawyerstrong/second-look.git
cd second-look
./install.sh
```

The script installs whatever is missing, then sets up second-look:

1. Python with common analysis libraries (pandas, scipy, statsmodels, matplotlib, openpyxl).
2. Claude Code itself.
3. The second-look files listed below. If one of them already exists and differs, the old copy is saved with a `.bak-<date>` ending.

It is safe to run again; anything already installed is skipped. If it ends by telling you to open a new Terminal, close this one and open a new one.

Then run `claude` and follow the prompts to sign in. It opens a sign-in page in Chrome. If Terminal then asks for a code, copy it from the Chrome page and paste it into Terminal with Ctrl+Shift+V. Type `/exit` to quit.

Install any further Python libraries with `sudo apt install python3-<name>`; this Linux blocks plain `pip install`. If you analyze in R, run `sudo apt install -y r-base`. The agents run your code to recheck numbers, so your analysis must run from this Terminal.

Where things end up:

| File | Goes to | What it does |
|---|---|---|
| `CLAUDE.md` | `~/.claude/rules/second-look.md` | Rules Claude follows in every session |
| `.claude/agents/reviewer.md` | `~/.claude/agents/` | The reviewer agent |
| `.claude/agents/devils-advocate.md` | `~/.claude/agents/` | The devil's advocate agent |
| `templates/analysis.md` | `~/.claude/second-look/analysis-template.md` | The write-up template Claude copies into new analyses |

(`~` is your Linux home folder. It shows up as **Linux files** in the ChromeOS Files app. Folders starting with `.` are hidden there; that is expected.)

**Check it worked.** Run `cd ~` and then `claude`.

- Type `@reviewer` and look at the suggestions that pop up: `reviewer (agent)` should be one. Do the same for `@devils-advocate`. Press Esc to clear the line.
- Type `/context` and press Enter. Under **Memory files**, `second-look.md` should be listed.

If either is missing, exit with `/exit`, start `claude` again, and recheck.

**Do a practice run before the assessment.** Do the setup and one full pass of the review loop (Section 4) on a small practice dataset well before the real assessment. If it is timed, you don't want Linux setup or the first sign-in using up the clock, and you will learn how long one review pass takes so you can plan around it.

## 3. Using the agents

Put your take-home in a folder under **Linux files** (in the Files app, drag the folder onto "Linux files"). Claude Code works only with files in the Linux environment, so a folder left in Downloads or Google Drive is invisible to it. Keep it out of the `second-look` folder itself. If your write-up is a Word or Google Doc, also save a copy as PDF in the folder so the agents can read it. Then start Claude Code in that folder:

```bash
cd ~/your-take-home
claude
```

Two prompts appear the first time:

- Claude asks whether you trust the folder. Choose yes for your own take-home folder.
- Claude asks before it runs a command or edits a file. Read what it wants to do, then approve or decline. Declining is fine; it will explain or try another way.

Ask for an agent by name in plain English:

> Use the reviewer agent on analysis.md. The data is data/results.csv and the code is analysis.py.

> Use the devils-advocate agent on this conclusion: "Condition B increased the response relative to condition A." Data is data/results.csv, code is analysis.py.

Three things to know:

- **Agents start fresh.** They do not see your conversation with Claude. Name every file they need: the write-up, the data, and the code.
- **Agents report; they don't fix.** Neither one edits your files. You decide which problems to act on.
- **They can be wrong.** An agent may flag something that is fine. Treat each item as a question to answer, not an order.

## 4. Worked example: the review loop

Say your folder holds `data/results.csv`, `analysis.py`, and a draft write-up `analysis.md` concluding that condition B gave a higher response than condition A.

**Step 1: Draft.** Start from the write-up template. When you begin an analysis in a folder with no write-up, Claude offers to copy it in as `analysis.md`; say yes. If it doesn't offer, ask: "Copy the second-look template into this folder." Fill in the Plan and Experimental methods sections with Claude before you look at any results. If the assessment specifies its own format, use that instead and fit the template's sections into it. Work through the analysis with Claude as usual. Because of the rules, expect it to list assumptions before computing, to ask you for any threshold or constant it doesn't have, and to show the code behind each number.

**Step 2: Review.**

> Use the reviewer agent on analysis.md. Data: data/results.csv. Code: analysis.py.

It returns a numbered list, worst first. An item looks like this (made-up numbers, for illustration):

```
1. [Severity: changes conclusion]
   Where: analysis.py, line 14
   Problem: Three rows are dropped by a hard-coded filter; analysis.md never mentions it.
   Evidence: df = df[df.response < 50]. With the rows included, the B-A difference falls from 6.1 to 2.3.
   Fix: State the exclusion rule and its basis, and report the result with and without those rows.
```

**Step 3: Revise.** Fix what you agree with. Ask Claude for help ("Report the result with and without the excluded rows"). For anything you leave alone, be able to say why. Re-run the reviewer if you made large changes.

**Step 4: Devil's advocate.** Give it your conclusion in one sentence:

> Use the devils-advocate agent on this conclusion: "Condition B gave a higher response than condition A." Data: data/results.csv. Code: analysis.py.

It returns counter-arguments labeled **Plausible** (something in your data points to it) or **Possible** (nothing rules it out), and ends with the one you most need to address. For example, if all B samples were run on a later date than all A samples, it will flag run date as a confound.

**Step 5: Finalize.** For each Plausible counter-argument, either rule it out with a check you actually ran or add it to your write-up as a stated limitation. Possible ones belong in a short limitations section only if a reader would reasonably raise them. Then soften any claim the evidence doesn't fully earn ("consistent with" instead of "shows").

**Keep an AI log as you go.** For each reviewer or devil's-advocate item, write one line: what it flagged, whether you acted on it, and why. Include a short version in your submission, such as "AI review flagged X; I confirmed it and reran without the excluded rows" or "AI suggested confound Y; ruled out because Z." Items you overruled are as useful to show as items you accepted.

## 5. Update or remove

**Update:** in the `second-look` folder, run:

```bash
git pull && ./install.sh
```

**Remove:** in the `second-look` folder, run `./install.sh --uninstall`. It deletes the four second-look files and nothing else; Claude Code and the Python libraries stay installed.
