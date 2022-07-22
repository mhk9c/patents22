import os
from dotenv import load_dotenv
import sqlalchemy as db
from datetime import datetime
import pandas as pd
import logging
from sqlalchemy.engine.reflection import Inspector



class DBTools:
    def __init__(self): 
        load_dotenv()        
        self.USERNAME = os.getenv('USERNAME')
        self.PASSWORD = os.getenv('PASSWORD')
        self.HOST = os.getenv('HOST')
        self.DATABASE = os.getenv('DATABASE')
        self.PORT= os.getenv('PORT')        
        self.mysql_engine = db.create_engine('mysql+pymysql://{0}:{1}@{2}:{3}/{4}'.format(self.USERNAME, self.PASSWORD, self.HOST, self.PORT, self.DATABASE))           


    def create_method(self, meta:db.sql.schema.MetaData):
        '''
        Upserts a data frame into the database.
        '''
        def method(table, conn, keys, data_iter):
            sql_table = db.Table(table.name, meta, autoload=True)
            insert_stmt = db.dialects.mysql.insert(sql_table).values([dict(zip(keys, data)) for data in data_iter])        
            upsert_stmt = insert_stmt.on_duplicate_key_update({x.name: x for x in insert_stmt.inserted})           
            conn.execute(upsert_stmt)
        return method


    def get_table_columns(self, table_name):
        # print(f"getting keys for {table_name}")
        meta_data = db.MetaData(bind=self.mysql_engine)
        db.MetaData.reflect(meta_data)
        table_meta = meta_data.tables[table_name]
        # print(table_meta.columns)        
        return [x.name for x in list(table_meta.columns)]       


    def insert_df(self, _df:pd.DataFrame, table_name:str, Filename="")->None:  
        '''
        Inserts a data frame into the database. Stright insert into the database.
        Should use this when you don't need to upsert.     
        '''  
        try:    
            with self.mysql_engine.begin() as connection:                        
                _df.to_sql(table_name, con=connection, if_exists='append', index=False)             
        except Exception as e:              
            logging.error(f'error : {e} ')


    def upsert_df(self, _df:pd.DataFrame, table_name:str, filename="")->None:
        '''
        Uses upserts to insert/update data into a table. Use on data that doesn't change often.    
        '''            
        try:
            with self.mysql_engine.begin() as connection:                                    
                meta = db.MetaData(connection)            
                method = self.create_method(meta)            
                # This method assumes that we have a primary key on the table
                _df.to_sql(table_name, connection, if_exists='append', method=method, index=False)   
        except Exception as e:
            logging.error(e)


    def get_df(self, table_name:str, where_clause:str="")->pd.DataFrame:
        '''
        Returns a data frame from the database.
        '''
        try:
            with self.mysql_engine.begin() as connection:
                sql_table = db.Table(table_name, db.MetaData(connection), autoload=True)
                query = db.select([sql_table])
                if where_clause:
                    query = query.where(where_clause)
                df = pd.read_sql(query.compile(compile_kwargs={'literal_binds': True}), self.mysql_engine)
                df = df[self.get_table_columns(table_name)]
                return df
        except Exception as e:
            logging.error(e)

    def truncate_table(self, table_name:str)->None:
        '''
        Truncates a table.
        '''
        verification = input("Are you sure you want to truncate table {0}? (y/n)".format(table_name))
        if verification == "y":            
            try:
                with self.mysql_engine.begin() as connection:
                    sql_table = db.Table(table_name, db.MetaData(connection), autoload=True)
                    connection.execute(sql_table.delete())
            except Exception as e:
                logging.error(e)

    def truncate_and_insert_df(self, _df:pd.DataFrame, table_name:str)->None:
        '''
        Truncates a table and inserts a data frame.
        '''
        try:
            with self.mysql_engine.begin() as connection:
                sql_table = db.Table(table_name, db.MetaData(connection), autoload=True)
                connection.execute(sql_table.delete())
                _df.to_sql(table_name, con=connection, if_exists='append', index=False)
        except Exception as e:
            _df.to_sql(table_name, con=connection, if_exists='append', index=False)
            logging.error(e)

    



    