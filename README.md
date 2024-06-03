# Projects

Here, I'll share with you some scripts created to solve problems and automate repetitive activities.

# Deploy database - Shellscript
Script created to automate customer deployment: it performs a git clone from the customer's repository, executes commands to prepare and isolate the database, applies all scripts to the database sorted by change number and owner, and reports all results and logs via email to the customer. After applying the packages, the database is made available.

# Exadata Backup Execution - Shellscript
Script created to automate backup execution: it performs a check to ensure the database is online in the RAC node with 4 nodes, and executes the script remotely using the DCLI Exadata tool.

# Client Product Classification - Python
Script created to help customers classify clients by their most purchased products and assign them to a label group. This script generates new reports with classifications that will be consumed in a Power BI dashboard created by me.

# Create Html on demand - Python
Script created to read a data from database and make a html report with a button to fix the problem calling a rundeck job.

# Guitar Classifier 
Project create to study library fastAI, this project can identify with type of guitar are in the image. Used to learn regarding machine learning and deeplearning.
