import os
from dotenv import load_dotenv
import cgi
import requests
from pathlib import Path
from urllib.parse import urlparse, unquote
from urllib.request import urlopen
from urllib.request import urlretrieve
import cgi
from requests.exceptions import RequestException
import zipfile


class FileTools:
    load_dotenv()   
    MYDIR = os.getenv('MYDIR') 

    def __init__(self): 
        pass



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
    def get_file(cls, url, filename=None):

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
    



