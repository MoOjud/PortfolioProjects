#import libraries

import pandas as pd
import csv
import requests
from bs4 import BeautifulSoup as bs
import json
import time

#Creating the base URL
BaseURL = 'https://www.kaggle.com/'

#Create a list of the full url of the users whose info we want to scrape
user_url = []
with open('Kaggle Users - Batch 1.csv', 'r', encoding="utf8") as f:
    test = csv.DictReader(f)
    #header = next(test)
    for col in test:
        user_url.append(BaseURL+col['UserName'])
       

#print(usernames)
#print(user_url)

#define a function to return the user details
def parse_user(url):
    """Get the user data point and return dictionary of required values"""
    response = requests.get(url)
    content = response.text
    result = bs(content, 'html.parser')
    user = result.find('script', {'class': "kaggle-component"})
    usertext = user.get_text()
    index1 = usertext.find('Kaggle.State.push(')
    index2 = usertext.find(');performance &&')
    userdetails = usertext[index1+18:index2]
    return userdetails

#define a function to clean the user details
def clean_string(input_string):
    bad_char = ['\\n', '\\r']
    userdetails_cleaned = input_string
    for char in bad_char:
        userdetails_cleaned = userdetails_cleaned.replace(char, '')
    return userdetails_cleaned

#define a function to return the key value pair of user details i'm interested in
def get_details(userdetails_cleaned):
    user_dict = json.loads(userdetails_cleaned)
    keys =['userId','userName','country', 'region', 'city', 'occupation', 'organization', 'websiteUrl', 'bio', 'userJoinDate', 'userLastActive', 'performanceTier', 'gitHubUserName', 'linkedInUrl', 'twitterUserName', 'displayName', 'userAvatarUrl', 'canCreateDatasets', 'userAllowsUserMessages']
    return {key:value for key,value in user_dict.items() if key in keys}
    time.sleep(5)
    
    


#define a master function that calls all the other functions and stores he scrapped details in a dataframe
def scrape_users(path=None):
     """Get the kaggle user details and write them to CSV file """
     if path is None:
        path = 'Kaggle-Users-Batch 1 result.csv'
        
        print('Requesting html page')
        print('Extracting user details')
        print('Parsing user details')
        user_data = [get_details(clean_string(parse_user(url))) for url in user_url]

        print('Save the data to a CSV')
        users_df = pd.DataFrame(user_data)
        users_df.to_csv(path, index=False, header=True)
    
        #This return statement is optional, we are doing this just analyze the final output 
        return users_df 


users_df = scrape_users()





