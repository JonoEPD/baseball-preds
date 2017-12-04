# computes WAR (y) values

batting_years = 10
pitching_years = 9
offset = 7

# calc and dump batting y values
by_dict = {}
with open('batting_y.csv') as f:
    batting = csv.reader(f, delimiter=',')
    headers = next(batting, None)
    for row in batting:
        player_id = row[0]
        year_num = row[1]
        war = row[2]
        by_dict[player_id + '_' + str(year_num)] = war

with open('batting_yarr.csv','w') as f:
    writer = csv.writer(f, delimiter = ',')
    headers = ['player_id']
    headers.extend(list(range(batting_years)))
    writer.writerow(headers)
    for player in batter_list:
        x = [player]
        for year in range(batting_years):
            yr = year + offset
            iden = player + '_' + str(yr)
            try:
                val = by_dict[iden]
                x.append(val)
            except KeyError:
                x.append(0) # no player activity for that year
        writer.writerow(x)


# calc and dump pitching y values
py_dict = {}
with open('pitching_y.csv') as f:
    pitching = csv.reader(f, delimiter=',')
    headers = next(pitching, None)
    for row in pitching:
        player_id = row[0]
        year_num = row[1]
        war = row[2]
        py_dict[player_id + '_' + str(year_num)] = war

with open('pitching_yarr.csv','w') as f:
    writer = csv.writer(f, delimiter = ',')
    headers = ['player_id']
    headers.extend(list(range(pitching_years)))
    writer.writerow(headers)
    for player in pitcher_list:
        x = [player]
        for year in range(pitching_years):
            yr = year + offset
            iden = player + '_' + str(yr)
            try:
                val = py_dict[iden]
                x.append(val)
            except KeyError:
                x.append(0) # no player activity for that year
        writer.writerow(x)
