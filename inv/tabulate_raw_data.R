suppressMessages(library(dplyr))

cmds = c('du /project/mscamras/Data/*/*/raw_data/*.dat', 'du /project/mscamras/Data/*/*/raw_data/*/*.dat')

returns = c()
for (cmd in cmds) {
    returns = c(returns, system(cmd, intern=TRUE))
}

size = c()
files = c()
for (ret in strsplit(returns, "\t")) {
    size = c(size, ret[1])
    files = c(files, ret[2])
}

dup = files %>% sapply(basename) %>% unname() %>% duplicated()
files = files[nchar(size) > 4 & !dup]

sprintf("Total number of files is %s. ", length(files)) %>% write(stderr())

# Tabulate per subject per site
subj = sapply(strsplit(files, "/"), function(x) x[5])
site = sapply(strsplit(files, "/"), function(x) x[6])

df = data.frame(files = files, subject = subj, site = site)

# How many files per subject and site
df %>% count(subject, site) %>% write.csv(stdout(), row.names=FALSE)

# Compare with onscanner reconstructed
nifti = system("ls /project/mscamras/Data/*/*/NIFTI/*SAG*FL*ND*.nii.gz", intern=TRUE)