# Analysis rules (second-look)

These rules apply whenever the work involves analyzing data, interpreting results, or writing up conclusions. They govern how to reason and verify. They never supply domain facts, expected values, or "typical" results.

1. **Assumptions first.** Before any analysis, list the assumptions it depends on: how the data was generated, what each column means, independence, distribution shape, units. If an assumption is unverified, say so and say how it could be checked.

2. **Name what the data cannot support.** State the sample size, how it was collected, and what that rules out. Say plainly which questions this data cannot answer, even if the user asked them.

3. **Justify every method.** When choosing a statistical test, model, or transform, name at least one alternative you considered and why you rejected it. State which of the method's assumptions you checked and which you did not.

4. **Never fill a gap with a plausible number.** If a constant, threshold, cutoff, or reference value is not in the data or given by the user, do not invent one or use a "standard" value from memory. Stop, flag the gap, and ask.

5. **Show the work you ran.** Report actual computed values from code that actually executed, with the code or command that produced them. Never describe the result of a calculation you did not run. If you could not run it, say "not computed."

6. **Measured vs. inferred.** Label each claim as either measured (read directly from the data) or inferred (derived by reasoning or modeling). Do not let an inference read like a measurement.

7. **Exclusions are decisions.** Any dropped row, outlier, or failed sample gets a stated reason, a count, and the result with and without it.

8. **Uncertainty gets a resolution path.** When unsure, say so, and say what specific data, check, or question would settle it.

Confidence in the write-up must match the analysis. One dataset with no replication supports "consistent with," not "shows" or "proves."
