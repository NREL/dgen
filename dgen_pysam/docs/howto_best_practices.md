#Analysis best practices:
- Every substantial modeling task requires:
	1. A dedicated database
	2. A dedicated github branch
  The databased and github branch should be named identically for each future reproducibility.
- Results schemas:
	- Results schemas will accumulate and clutter the database if you don't actively manage them. The options for manging them are:
		1. Change delete_output_schema in config.py to: True
		2. Manually delete output schemas from PG Admin:
			SELECT diffusion_shared.drop_results_schemas();
			This function will not delete the schemas themselves, but will create the set of sql statements required to drop the schemas. To execute the statements, copy and paste them yoru query window and then run in sets of 5-7 lines at a time. If you try to run with more statements than that, you will likely run into an error that says something about "max transaction locks" or "shared memory exceeded".
#Development best practices:
- changes made to the database need to be replicated on both gispgdb and dnpdb001
	- if you make changes to only one of the two databases, open a new issue with high priority, assigned to mgleason, indicating what you changed and on which database. provide a commit hash, if appropriate.
- if you open an issue, be sure to assign it each of the following:
	- a milestone
	- a priority level
	- an assignee
- if you hack a solution into the code (e.g., loading something from csv instead of the database, manually excluding something from a sql query ,etc.), open a new issue referencing the commit hash, assigned to mgleason
- to the degree possible, avoid adding any decision logic or complex code to dgen.py (i.e., no loops, no if/else clauses, no sql statements). Any logic of this type should be either integrated into existing functions or added as new functions.
