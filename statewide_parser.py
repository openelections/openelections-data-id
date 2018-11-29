import xlrd
import csv

results = []

offices = { 'Governor': range(1,5), 'Lieutenant Governor': range(6,1) }

book = xlrd.open_workbook("/Users/dwillis/Downloads/18gen_stwd_pct.xls")
# let's use the first sheet (Python starts counting at 0)
sheet = book.sheets()[3]
# now we'll loop through all of the rows in that sheet - try print(sheet.nrows) before to see how many
parties = sheet.row_values(3)[1:]
candidates = sheet.row_values(4)[1:]

for row in range(5, sheet.nrows):
    if sheet.cell(row,1).value == '' and sheet.cell(row,0).value != '':
        # this is a county
        county = sheet.cell(row,0).value.title()
    elif sheet.cell(row,0).value == '':
        next
    else:
        print(sheet.row_values(row))
        precinct = sheet.cell(row,0).value
        votes = [c for c in sheet.row_values(row)[1:]]
        cands_parties_votes = zip(candidates, parties, votes)
        for candidate, party, votes in cands_parties_votes:
            results.append([county, precinct, None, None, party.strip(), candidate.strip(), votes])

with open('statewide.csv','wt') as csvfile:
    csvwriter = csv.writer(csvfile)
    csvwriter.writerows(results)
