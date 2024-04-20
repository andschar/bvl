# Script to combine and prepare BVL WstKulturHisorie data

# setup -------------------------------------------------------------------
require(data.table)
prj = '~/Projects/bvl'
cachedir = andmisc::file.path2(prj, 'cache')
datadir = andmisc::file.path2(prj, 'data')

# unzip -------------------------------------------------------------------
fl_zip = file.path(datadir, 'raw', 'WstKulturHistorie.tar.gz')
untar(fl_zip, exdir = basename(cachedir)) # NOTE basename is necessary because of bad tar() implementation. exdir translates to the -C flag and is also quoted, (e.g. -C '~/Projects/bvl/cache'). tar then assumes the string is one directory and not a path.

# data --------------------------------------------------------------------
l = list(
  readxl::read_excel(file.path(cachedir, "200701_WstKulturHistorie.xls")),
  readxl::read_excel(file.path(cachedir, "201201_WstKulturHistorie.xls"), sheet = 2),
  readxl::read_excel(file.path(cachedir, "201504_WstKulturHistorie.xls"), sheet = 2),
  readxl::read_excel(file.path(cachedir, "202007_WstKulturHistorie.xls"), sheet = 2),
  readxl::read_excel(file.path(cachedir, "202404_WstKulturHistorie.xlsx"), sheet = 2)
)
l = lapply(l, data.table::setDT)

# prep --------------------------------------------------------------------
id_vars = c("Einsatzgebiet", "Kultur", "KodeKultur",
            "Wirkstoff", "WstNr", "Wirkungsbereich")
# merge
out = Reduce(function(...) merge(..., by = id_vars, all = TRUE), l)
# remove duplicate rows
cols = grep('\\.x', names(out), value = TRUE)
out = out[ , .SD, .SDcols =! cols ]
setnames(out, sub('.y', '', names(out), fixed = TRUE))
# replace German 'Okt' with english 'Oct'
names(out) = sub('Okt', 'Oct', names(out), fixed = TRUE)
# convert to actual date strings
names(out)[7:ncol(out)] = format(as.IDate(paste0('01', names(out)[7:ncol(out)]), '%d%b%y'), '%Y%m%d')
# colorer
setcolorder(out, c(id_vars, sort(names(out)[7:ncol(out)])))

# write -------------------------------------------------------------------
fl = paste0(min(names(out)[7:ncol(out)]), '_', max(names(out)[7:ncol(out)]), '_WstKulturHistorie.tsv.gz')
fwrite(out, file.path(datadir, fl), sep = '\t', compress = 'gzip')
