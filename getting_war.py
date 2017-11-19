import csv
import pandas as pd
import urllib2
from bs4 import BeautifulSoup
from bs4 import Comment

BASE_URL = 'https://www.baseball-reference.com/players/'

def main():
	# get players
	pids = get_player_ids()
	pl_urls = prep_urls(pids)

	# loop over and scrape
	pl_yr_war = get_yrs_and_war(pl_urls)
	write_to_file(pl_yr_war)

	# export

def get_player_ids():
	batting = pd.read_csv('batting.csv')
	pids = batting.loc[:,'player_id']
	pids = pids.drop_duplicates()
	pids.index = range(pids.shape[0])

	for i in range(0, pids.shape[0]):
		if pids.loc[i] == 'richajr01':
			pids.loc[i] = 'richaj.01'
		if pids.loc[i] == 'washiul01':
			pids.loc[i] = 'washiu_01'
		if pids.loc[i] == 'pierzaj01':
			pids.loc[i] = 'pierza.01'
		if pids.loc[i] == 'obriepe03':
			pids.loc[i] = 'o\'bripe03'
		if pids.loc[i] == 'omallto01':
			pids.loc[i] = 'o\'malto01'
		if pids.loc[i] == 'obriech01':
			pids.loc[i] = 'o\'brich01'
		if pids.loc[i] == 'oneilpa01':
			pids.loc[i] = 'o\'neipa01'
		if pids.loc[i] == 'surhobj01':
			pids.loc[i] = 'surhob.01'
		if pids.loc[i] == 'snowjt01':
			pids.loc[i] = 'snowj.01'
		if pids.loc[i] == 'oleartr01':
			pids.loc[i] = 'o\'leatr01'
		if pids.loc[i] == 'drewjd01':
			pids.loc[i] = 'drewj.01'
		if pids.loc[i] == 'burneaj01':
			pids.loc[i] = 'burnea.01'
		if pids.loc[i] == 'furcara01':
			pids.loc[i] = 'furcara02'
		if pids.loc[i] == 'harriwi01':
			pids.loc[i] = 'harriwi02'
		if pids.loc[i] == 'delarjo01':
			pids.loc[i] = 'rosajo01'

	return pids

def prep_urls(pids):
	initial = pids.str[0]
	url = BASE_URL + initial + '/' + pids + '.shtml'
	d = {'player_id': pids, 'url': url}
	pl_urls = pd.DataFrame(data=d)
	return pl_urls

def get_yrs_and_war(pl_urls):
	
	rows_list = []

	for i in range(0,pl_urls.shape[0]):
		pid = pl_urls.loc[i,'player_id']
		if pid == 'richaj.01':
			pid = 'richajr01'
		if pid == 'washiu_01':
			pid = 'washiul01'
		if pid == 'pierza.01':
			pid = 'pierzaj01'
		if pid == 'o\'bripe03':
			pid = 'obriepe03'
		if pid == 'o\'malto01':
			pid = 'omallto01'
		if pid == 'o\'brich01':
			pid = 'obriech01'
		if pid == 'o\'neipa01':
			pid = 'oneilpa01'
		if pid == 'surhob.01':
			pid = 'surhobj01'
		if pid == 'snowj.01':
			pid = 'snowjt01'
		if pid == 'o\'leatr01':
			pid = 'oleartr01'
		if pid == 'drewj.01':
			pid = 'drewjd01'
		if pid == 'burnea.01':
			pid = 'burneaj01'
		if pid == 'furcara01':
			pid = 'furcara02'
		if pid == 'harriwi01':
			pid = 'harriwi02'
		if pid == 'rosajo01':
			pid = 'delarjo01'

		print 'scraping pid', pid
		response = urllib2.urlopen(pl_urls.loc[i,'url'])
		pl_soup = BeautifulSoup(response, 'html.parser')

		test = pl_soup.select('#all_batting_value')
		comments = test[0].find_all(string=lambda text:isinstance(text,Comment))
		com_soup = BeautifulSoup(comments[0], 'html.parser')

		years = com_soup.select('tbody th[data-stat="year_ID"]')
		wars = com_soup.select('tbody td[data-stat="WAR"]')
		pids = [pid]*len(years)

		for j in range(0, len(years)):
			if len(years[j].get_text()) > 1:
				rowdict = {}
				rowdict['player_id'] = pid
				rowdict['year'] = years[j].get_text()
				rowdict['WAR'] = wars[j].get_text()
				rows_list.append(rowdict)

	data = pd.DataFrame(rows_list)

	return data

def write_to_file(data):
	filename = 'batting_war.csv'
	handle = open(filename, 'w')
	data.to_csv(handle, index=False)


if __name__ == '__main__':
    main()