import os
from dotenv import load_dotenv
import cgi
from numpy import concatenate
import requests
from pathlib import Path
from urllib.parse import urlparse, unquote
from urllib.request import urlopen
from urllib.request import urlretrieve
import cgi
from requests.exceptions import RequestException
import zipfile
import pandas as pd
import csv
import pyarrow


class FileTools:
    load_dotenv()   
    MYDIR = os.getenv('MYDIR') 

    def __init__(self): 
        pass

    @classmethod
    def save_df_as_csv(cls, df, filename):
        df.to_csv(cls.get_full_file_path(f'{filename}'), index=False, quoting=csv.QUOTE_NONNUMERIC)
        return filename

    @classmethod
    def load_df_from_csv(cls,filename):
        return pd.read_csv(cls.get_full_file_path(filename))        

    @classmethod
    def save_df_as_parquet(cls, df, filename):
        df.to_parquet(cls.get_full_file_path(filename), compression='gzip')
        return filename

    @classmethod
    def load_df_from_parquet(cls, filename):
        return pd.read_parquet(cls.get_full_file_path(filename))
        

    @classmethod
    def generate_csv_file_list(cls, path:str, file_list:list())->list:
        '''
        Generates a list of all csv files in a directory.
        '''     
        for root, dirs, files in os.walk(path):
            for file in files:
                if file.endswith(".csv"):
                    file_list.append((os.path.join(root, file), file))
        return file_list

    @classmethod
    def check_directory(cls, directory_path:str)->bool:
        '''Check if directory exists, if not, create it'''        
        CHECK_FOLDER = os.path.exists(f'{directory_path}')    
        # If folder doesn't exist, then create it.
        if not CHECK_FOLDER:
            os.makedirs(directory_path)
        return CHECK_FOLDER


    @classmethod
    def check_file_from_url(cls, url):
        return cls.check_file(cls.get_full_file_path(cls.get_filename_from_url(url)))


    @classmethod
    def check_file(cls, file_path:str)->bool:
        '''Check if file exists, if not, create it'''        
        CHECK_FILE = os.path.exists(f'{file_path}')    
        return CHECK_FILE

    @classmethod
    def unzip_file(cls, file_path:str)->None:
        '''Unzip a file'''        
        with zipfile.ZipFile(file_path, 'r') as zip_ref:
            zip_ref.extractall(cls.MYDIR)


    @classmethod
    def get_full_file_path(cls, filename):
        cls.check_directory(FileTools.MYDIR)
        full_file_path = os.path.join(FileTools.MYDIR, filename)        
        return full_file_path

    @classmethod
    def get_filename_from_url(cls, url:str)->str:
        '''
        Get the filename from a url.
        '''
        parsed_url = urlparse(url)
        filename = os.path.basename(parsed_url.path)        
        return filename


    @classmethod
    def get_file_from_url(cls, url, filename=None):

        try:
            with requests.get(url) as r:
                
                if filename:
                    pass
                elif "Content-Disposition" in r.headers.keys():
                    value, params = cgi.parse_header(r.headers["Content-Disposition"])
                    filename = params["filename"]               
                else:
                    filename = unquote(urlparse(url).path.split("/")[-1])
                        
                full_file_path = cls.get_full_file_path(filename)
                open(full_file_path, "wb").write(r.content) 
                print(f'Saved {full_file_path}')
        except RequestException as e:
            print(e)

        return full_file_path


    @classmethod
    def concatenate_dataframes(cls, df_list:list())->pd.DataFrame:
        
        '''
        Concatenate a list of dataframes.
        '''
        return pd.concat(df_list, axis=0)



