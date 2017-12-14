import csv
import pandas as pd
import urllib2
from bs4 import BeautifulSoup
from bs4 import Comment

BASE_URL = 'https://www.baseball-reference.com/players/'
IDS_TO_BREF = {
	'richajr01':'richaj.01', 
	'washiul01':'washiu_01',
	'pierzaj01':'pierza.01',
	'obriepe03':'o\'bripe03',
	'omallto01':'o\'malto01',
	'obriech01':'o\'brich01',
	'oneilpa01':'o\'neipa01',
	'surhobj01':'surhob.01',
	'snowjt01':'snowj.01',
	'oleartr01':'o\'leatr01',
	'drewjd01':'drewj.01',
	'burneaj01':'burnea.01',
	'furcara01':'furcara02',
	'harriwi01':'harriwi02',
	'delarjo01':'rosajo01',
	'dacqujo01':'d\'acqjo01',
	'damicje01':'d\'amije01',
	'dickera01':'dicker.01',
	'garcifr02':'garcifr03',
	'hinchaj01':'hincha.01',
	'jimenda01':'jimend\'01',
	'lopezro01':'lopezro02',
	'macdobo01':'macdoro01',
	'mathetj01':'mathet.01',
	'nitkocj01':'nitkoc.01',
	'oberrmi01':'o\'bermi01',
	'oconnja02':'o\'conja02',
	'onealra01':'o\'neara01',
	'ortizra01':'ortizra02',
	'philljr01':'phillj.01',
	'ramirju01':'ramirju02',
	'redmati01':'redmaju01',
	'reynorj01':'reynor.01',
	'romerjc01':'romerj.01',
	'ryanbj01':'ryanb.01',
	'sabatcc01':'sabatc.01',
	'santafp01':'santaf.01',
	'santajo01':'santajo02',
	'stclara01':'st.clra01',
	'stricsc01':'stricsc02',
	'tucketj01':'tucket.01',
	'walkeke01':'walkeke02',
	'jonesja04':'jonesja05',
	}
IDS_FROM_BREF = {
	'richaj.01':'richajr01', 
	'washiu_01':'washiul01',
	'pierza.01':'pierzaj01',
	'o\'bripe03':'obriepe03',
	'o\'malto01':'omallto01',
	'o\'brich01':'obriech01',
	'o\'neipa01':'oneilpa01',
	'surhob.01':'surhobj01',
	'snowj.01':'snowjt01',
	'o\'leatr01':'oleartr01',
	'drewj.01':'drewjd01',
	'burnea.01':'burneaj01',
	'furcara02':'furcara01',
	'harriwi02':'harriwi01',
	'rosajo01':'delarjo01',
	'd\'acqjo01':'dacqujo01',
	'd\'amije01':'damicje01',
	'dicker.01':'dickera01',
	'garcifr03':'garcifr02',
	'hincha.01':'hinchaj01',
	'jimend\'01':'jimenda01',
	'lopezro02':'lopezro01',
	'macdoro01':'macdobo01',
	'mathet.01':'mathetj01',
	'nitkoc.01':'nitkocj01',
	'o\'bermi01':'oberrmi01',
	'o\'conja02':'oconnja02',
	'o\'neara01':'onealra01',
	'ortizra02':'ortizra01',
	'phillj.01':'philljr01',
	'ramirju02':'ramirju01',
	'redmaju01':'redmati01',
	'reynor.01':'reynorj01',
	'romerj.01':'romerjc01',
	'ryanb.01':'ryanbj01',
	'sabatc.01':'sabatcc01',
	'santaf.01':'santafp01',
	'santajo02':'santajo01',
	'st.clra01':'stclara01',
	'stricsc02':'stricsc01',
	'tucket.01':'tucketj01',
	'walkeke02':'walkeke01',
	'jonesja05':'jonesja04',
	}

def main():
	# get players
	pids = get_player_ids()
	pl_urls = prep_urls(pids)

	# loop over and scrape
	(batdata, pitchdata) = get_yrs_and_war(pl_urls)
	write_to_file(batdata, pitchdata)

	# export

def get_player_ids():
	players = pd.read_csv('1970fas.csv')

	pids = players.loc[:,'player_id']
	pids = pids.drop_duplicates()
	pids.index = range(pids.shape[0])

	#swap data ids to bbref ids
	for i in range(0, pids.shape[0]):
		if pids[i] in IDS_TO_BREF:
			pids[i] = IDS_TO_BREF[pids[i]]

	return pids

def prep_urls(pids):
	initial = pids.str[0]
	url = BASE_URL + initial + '/' + pids + '.shtml'
	d = {'player_id': pids, 'url': url}
	pl_urls = pd.DataFrame(data=d)
	return pl_urls

def get_yrs_and_war(pl_urls):
	
	bat_rows_list = []
	pitch_rows_list = []

	for i in range(0, pl_urls.shape[0]): #pl_urls.shape[0]
		pid = pl_urls.loc[i,'player_id']
		if pid in IDS_FROM_BREF:
			pid = IDS_FROM_BREF[pid]

		print 'player number', i
		print 'scraping pid', pid
		response = urllib2.urlopen(pl_urls.loc[i,'url'])
		pl_soup = BeautifulSoup(response, 'html.parser')

		bat_html = pl_soup.select('#all_batting_value')
		pos = 'P'
		
		if len(bat_html) > 0:
			comments = bat_html[0].find_all(string=lambda text:isinstance(text,Comment))
			bat_soup = BeautifulSoup(comments[0], 'html.parser')

			byears = bat_soup.select('tbody th[data-stat="year_ID"]')
			wars = bat_soup.select('tbody td[data-stat="WAR"]')
			posns = bat_soup.select('tbody td[data-stat="pos_season"]')
			ages = bat_soup.select('tbody td[data-stat="age"]')

			for j in range(0, len(byears)):
				if len(byears[j].get_text()) > 1:
					rowdict = {}
					rowdict['player_id'] = pid
					rowdict['year'] = byears[j].get_text()
					rowdict['WAR'] = wars[j].get_text()
					rowdict['age'] = ages[j].get_text()

					if '/' in posns[j].get_text():
						if len(posns[j].get_text().split('/')[0]) == 0:
							if '1' in posns[j].get_text():
								rowdict['position'] = 'Pitcher'
							else:
								rowdict['position'] = 'Non-Pitcher'
								pos = ''
						elif '1' in posns[j].get_text().split('/')[0]:
							rowdict['position'] = 'Pitcher'
						else:
							rowdict['position'] = 'Non-Pitcher'
							pos = ''
					elif '1' in posns[j].get_text():
						rowdict['position'] = 'Pitcher'
					else:
						rowdict['position'] = 'Non-Pitcher'
						pos = ''

					bat_rows_list.append(rowdict)

		if pos == 'P':
			pitch_html = pl_soup.select('#all_pitching_value')
			comments = pitch_html[0].find_all(string=lambda text:isinstance(text,Comment))
			pitch_soup = BeautifulSoup(comments[0], 'html.parser')

			pyears = pitch_soup.select('tbody th[data-stat="year_ID"]')
			pages = pitch_soup.select('tbody td[data-stat="age"]')
			pwars = pitch_soup.select('tbody td[data-stat="WAR_pitch"]')

			for j in range(0, len(pyears)):
				if len(pyears[j].get_text()) > 1:
					rowdict = {}
					rowdict['player_id'] = pid
					rowdict['year'] = pyears[j].get_text()
					rowdict['WAR'] = pwars[j].get_text()
					rowdict['age'] = pages[j].get_text()

					pitch_rows_list.append(rowdict)

	batdata = pd.DataFrame(bat_rows_list)
	pitchdata = pd.DataFrame(pitch_rows_list)

	return (batdata, pitchdata)

def write_to_file(batdata, pitchdata):
	bat_filename = 'batting_war.csv'
	pitch_filename = 'pitching_war.csv'

	bhandle = open(bat_filename, 'w')
	batdata.to_csv(bhandle, index=False)

	phandle = open(pitch_filename, 'w')
	pitchdata.to_csv(phandle, index=False)




if __name__ == '__main__':
    main()