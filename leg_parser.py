import xlrd
import unicodecsv

results = []

book = xlrd.open_workbook("/Users/derekwillis/Downloads/96gnlgcn.xls")
# let's use the first sheet (Python starts counting at 0)
sheet = book.sheets()[0]
# now we'll loop through all of the rows in that sheet - try print(sheet.nrows) before to see how many
for row in range(sheet.nrows):
    if sheet.cell(row,0).value == 'District/Candidate':
        next
    elif sheet.cell(row,0).value == '':
        next
    elif 'DIST' in sheet.cell(row,0).value:
        district = sheet.cell(row,0).value.replace("LEG DISTRICT ","").replace(' (Continued)','').replace("LEG. DIST. ","")
        counties = [c for c in sheet.row_values(row)[1:-1] if c != '']
    elif 'State Senate' in sheet.cell(row,0).value:
        office = 'State Senate'
        district_num = str(district)
    elif 'Senat' in sheet.cell(row,0).value:
        office = 'State Senate'
        district_num = str(district)
    elif 'State Represent' in sheet.cell(row,0).value:
        office = 'State Representative'
        district_num = str(district) + sheet.cell(row,0).value.replace('State Representative ','')
    else:
        print sheet.row_values(row)
        party, candidate = sheet.cell(row,0).value.split('-', 1)
        votes = [c for c in sheet.row_values(row)[1:-1] if c != '']
        county_votes = zip(counties, votes)
        for county, vote in county_votes:
            results.append([county, office, district_num, party.strip(), candidate.strip(), vote])

with open('state_leg.csv','wb') as csvfile:
    csvwriter = csv.writer(csvfile)
    csvwriter.writerows(results)
