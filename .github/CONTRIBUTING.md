# Contributing

There are only a few rules:
- Follow the commit convention as follows:
  - The name of the commit should be `module: change`
  - Try to be consistent with the module names; you can look at existing commits for the module names I use
  - If there is more than one change, the change in the commit name should be the most impactful change
  - Put other changes in the description
- Format your code
  - I use the vscode qml extension with default arguments to format the code, however you do not have to use it
  - Just try to follow the code style of the rest of the code and ensure that there is:
    - no trailing whitespace on any lines
    - a single space between operators
- No AI slop allowed
  - AI readme/docs slop = instant block
- PLEASE TEST YOUR PRS
  - I can't believe I have to put this here, but please test your PRs before submitting them
  - Your PR must not break anything currently existing, or specify in the description if it does
- PR descriptions should be descriptive
  - Please explain what the PR does and how to use it in your PR description
  - Also include any breaking changes and/or side effects of the PR
