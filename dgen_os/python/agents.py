import concurrent.futures as cf
from functools import partial
import os
import pandas as pd
import utility_functions as utilfunc
import config

# load logger
logger = utilfunc.get_logger()


class Agents(object):
    """
    Agents class instance
    """
    def __init__(self, agents_df):
        """
        Initialize Agents Class
        Parameters
        ----------
        agents_df : 'pd.df'
            Pandas Dataframe containing agents and their attributes.
            Index = agent ids, columns = agent attributes

        Returns
        -------
        agent_df : 'pd.df'
            Agents DataFrame
        agent_ids : 'ndarray'
            Array of agent ids
        agent_attrs : 'ndarray'
            Array of agent attributes
        attrs_types : 'pd.Series'
            Array of dtypes for each attribute
        """
        self.df = agents_df
        self.ids = agents_df.index
        self.attrs = agents_df.columns
        self.types = agents_df.dtypes

    def __len__(self):
        """
        Return number of agents
        """
        return len(self.ids)

    def __repr__(self):
        """
        Print number of agents and attributes
        """
        return ('{a} contains {n} agents with {c} attributes'
                .format(a=self.__class__.__name__,
                        n=len(self),
                        c=len(self.attrs)))

    @property
    def check_types(self):
        """
        Check to see if attribute types have changed
        """
        types = self.df.dtypes
        check = self.types == types

        if not all(check):
            print('Attribute dtypes have changed')

    @property
    def update_attrs(self):
        """
        Update agent class attributes
        """
        self.ids = self.df.index
        self.attrs = self.df.columns
        self.types = self.df.dtypes

    def __add__(self, df):
        """
        Add agents to agents
        Parameters
        ----------
        df : 'pd.df'
            Pandas Dataframe containing agents to be added

        Returns
        -------
        agent_df : 'pd.df'
            Updated Agents DataFrame
        agent_ids : 'ndarray'
            Updated array of agent ids
        """
        self.df = self.df.append(df)

        self.update_attrs

    def add_attrs(self, attr_df, on=None):
        """
        Add attributes to agents
        Parameters
        ----------
        df : 'pd.df'
            Pandas Dataframe containing new attributes for agents
        on : 'object'
            Pandas on kwarg, if None join on index

        Returns
        -------
        agent_df : 'pd.df'
            Updated Agents DataFrame
        attrs_types : 'pd.Series'
            Updated attribute types
        """
        if on is None:
            self.df = self.df.join(attr_df, how='left')
        else:
            self.df = self.df.reset_index()
            self.df = pd.merge(self.df, attr_df, how='left', on=on)
            self.df = self.df.set_index('agent_id')
        self.update_attrs

    def chunk_on_row(self, func, cores=1, in_place=True, **kwargs):
        """Wrapper function around apply_on_row with runtime tests."""

        results_df = self.run_with_runtime_tests(how_to_apply='chunk_on_row', func=func, cores=cores, **kwargs)

        if in_place:
            self.df = results_df
            self.df.set_index('agent_id', drop=True)
            self.update_attrs
        else:
            results_df.set_index('agent_id', drop=True)
            return results_df
    
    def on_frame(self, func, func_args=None, in_place=True, **kwargs):
        """Wrapper function around apply_on_frame with runtime tests."""

        results_df = self.run_with_runtime_tests(how_to_apply='on_frame', func=func, func_args=func_args, cores=None, **kwargs)

        if in_place:
            self.df = results_df
            self.df.set_index('agent_id', inplace=True, drop=True)
            self.update_attrs
        else:
            results_df.set_index('agent_id', inplace=True, drop=True)
            return results_df
    
    def run_with_runtime_tests(self, how_to_apply, func, func_args=None, cores=None, **kwargs):
        """
        Apply a function to a dataframe with:
            -on_frame
            -on_row
            -chunk_on_row
        While conducting run time tests.

        Tests
        -----
        - Dropped Columns: Columns were in df_in, but not in df_out
        - Duplicated Columns: New columns appear with a '_x' appended, indicating a pandas merge error
        - Null Values in New Columns: Can be overridden with config variable.
        - dType Change in Old Columns: Can be overridden with config variable.
        - Consistant Length: Number of rows (agents) hasn't changed.
        - Consistant agent_ids: agent_ids in df_in match those in df_out

        Notes
        -----
        - Returns a df with agent_id as a *column*, not as the index. 
            -THIS ALLOWS US TO GET RID OF MOST df.set_index('agent_id') AND df.reset_index(drop=False) THROUGHOUT THE CODEBASE.
        - Drops 'bad columns' that are created by merge errors or index resets ['level_0','index']

        """
        # --- Drop any bad columns intially there ---
        self.df = self.df.drop(['level_0','index'], axis='columns', errors='ignore')

        # --- reset and initialize agent_id list ---
        if 'agent_id' not in self.df.columns:
            if self.df.index.name == 'agent_id':
                self.df.reset_index(drop=False, inplace=True) #if agent_id is the name of the index, make it a column instead
        
        # --- initialize variables for runtime tests ---
        initial_len  = len(self.df)
        initial_columns = list(self.df.columns)
        initial_dtypes = list(self.df.dtypes)

        try:
            initial_agent_ids = list(self.df.sort_values('agent_id')['agent_id'])
        except KeyError as e:
            logger.error(e)
            logger.error('No agent_id column was found when applying a function to the agent_df.')

        # --- apply functions ---
        if how_to_apply == 'on_row':
            results_df = self.apply_on_row(func, cores=cores, **kwargs)
            results_df['agent_id'] = results_df['agent_id'].astype(int)
            results_df = pd.merge(self.df, results_df, on='agent_id')
        elif how_to_apply == 'chunk_on_row':
            results_df = self.apply_chunk_on_row(func, cores=cores, **kwargs)
            results_df['agent_id'] = results_df['agent_id'].astype(int)
            results_df = pd.merge(self.df, results_df, on='agent_id')
        elif how_to_apply == 'on_frame':
            results_df = self.apply_on_frame(func, func_args=func_args, **kwargs)

        # --- Drop any bad columns added by function ---
        results_df = results_df.drop(['level_0','index'], axis='columns', errors='ignore')
        
        # --- reset and grab post agent_id list ---
        if 'agent_id' not in results_df.columns:
            if results_df.index.name == 'agent_id':
                results_df.reset_index(drop=False, inplace=True) #if agent_id is the name of the index, make it a column instead
        post_agent_ids = list(results_df.sort_values('agent_id')['agent_id'])

        # --- check df after apply ---
        post_len = len(results_df)
        post_columns = list(results_df.columns)
        duplicated_columns = ['_x' in c for c in post_columns] 
        new_columns = [c for c in post_columns if c not in initial_columns]
        post_dtypes = list(results_df[initial_columns].dtypes) 
        
        # --- runtime tests ---
        #check for columns that were dropped
        missing_columns = [c for c in initial_columns if c not in post_columns]
        missing_columns = [c for c in missing_columns if c not in config.MISSING_COLUMN_EXCEPTIONS]
        if len(missing_columns) > 0:
            raise ValueError("After applying a function, the following columns were mistakenly dropped: {}".format(missing_columns))

        #check for duplicated columns
        assert sum(duplicated_columns) == 0, "Columns were duplicated by a function gone wrong within on_frame"

        #check for NaNs in new columns
        null_columns = results_df[new_columns].columns[results_df[new_columns].isna().any()].tolist()
        null_columns = [c for c in null_columns if c not in config.NULL_COLUMN_EXCEPTIONS]
        if len(null_columns) > 0:
            raise ValueError("After applying a function, the following columns have NaN values: {}".format(null_columns))

        #check for consistant len(df)
        assert initial_len == post_len, "agent_df len changed by a function applied on_frame"

        #check for consistant dtypes
        changed_dtypes = []
        for i in range(len(initial_columns)):
            if initial_dtypes[i] != post_dtypes[i]:
                if initial_dtypes[i] != 'O': #pandas 'object' type, could mean that its a string
                    changed_dtypes.append(initial_columns[i])
        changed_dtypes = [c for c in changed_dtypes if c not in config.CHANGED_DTYPES_EXCEPTIONS]
        if len(changed_dtypes) > 0:
            raise TypeError("After applying a function, the following columns changed dtypes: {}".format(changed_dtypes))

        #check that agent_ids haven't changed
        assert initial_agent_ids == post_agent_ids, "The order or content of agent_ids has changed"

        return results_df

    def apply_on_row(self, func, cores=None, **kwargs):
        """
        Apply function to agents on an agent by agent basis. Function should
        return a df to be merged onto the original df.
        Parameters
        ----------
        func : 'function'
            Function to be applied to each agent
            Must take a pd.Series as the argument
        cores : 'int'
            Number of cores to use for computation
        in_place : 'bool'
            If true, set self.df = results of compute
            else return results of compute
        **kwargs
            Any kwargs for func

        Returns
        -------
        results_df : 'pd.df'
            Dataframe of agents after application of func
        """

        if cores == 1:
            apply_func = partial(func, **kwargs)
            results_df = self.df.apply(apply_func, axis=1)
        else:
            if 'ix' not in os.name:
                EXECUTOR = cf.ThreadPoolExecutor
            else:
                EXECUTOR = cf.ProcessPoolExecutor

            futures = []
            with EXECUTOR(max_workers=cores) as executor:
                for _, row in self.df.iterrows():
                    futures.append(executor.submit(func, row, **kwargs))

                results = [future.result() for future in futures]

            results_df = pd.concat(results, axis=1).T

        return results_df

    def apply_chunk_on_row(self, func, cores=None, **kwargs):
        """
        Divide the dataframe into chunks according to the number of processors and 
        then apply function to agents on an agent by agent basis within that 
        dataframe chunk. Function should return a df to be merged onto the original df.
        Parameters
        ----------
        func : 'function'
            Function to be applied to each agent
            Must take a pd.Series as the argument
        cores : 'int'
            Number of cores to use for computation
        in_place : 'bool'
            If true, set self.df = results of compute
            else return results of compute
        **kwargs
            Any kwargs for func

        Returns
        -------
        results_df : 'pd.df'
            Dataframe of agents after application of func
        """
        print('\t\t\t============ APPLY CHUNK ON ROW ============')

        # --- apply function ---
        if cores is None:
            apply_func = partial(func, **kwargs)
            results_df = self.df.apply(apply_func, axis=1)
        else:
            if 'ix' not in os.name:
                EXECUTOR = cf.ThreadPoolExecutor
            else:
                EXECUTOR = cf.ProcessPoolExecutor

            logger.info('Number of Workers inside chunk_on_row is {}'.format(cores)) 
            futures = []
            chunk_size = int(self.df.shape[0]/cores)
            chunks = [self.df.loc[self.df.index[i:i + chunk_size]] for i in range(0, self.df.shape[0], chunk_size)]
            
            with EXECUTOR(max_workers=cores) as executor:
                for agent_chunks in chunks:
                    for _, row in agent_chunks.iterrows():
                        futures.append(executor.submit(func, row, **kwargs))
    
                    results = [future.result() for future in futures]
                results_df = pd.concat(results, axis=1, sort=False).T              

        return results_df

    def apply_on_frame(self, func, func_args, **kwargs):
        """
        Apply function to agents using agent.df
        Parameters
        ----------
        func : 'function'
            Function to be applied to agent.df
            Must take a pd.df as the arguement
        func_args : 'object'
            args for func
        in_place : 'bool'
            If true, set self.df = results of compute
            else return results of compute
        **kwargs
            Any kwargs for func

        Returns
        -------
        results_df : 'pd.df'
            Dataframe of agents after application of func
        """

        # --- apply function ---
        if func_args is None:
            results_df = func(self.df, **kwargs)
        elif isinstance(func_args, list):
            results_df = func(self.df, *func_args, **kwargs)
        else:
            results_df = func(self.df, func_args, **kwargs)
        
        return results_df

    def to_pickle(self, file_name):
        """
        Save agents to pickle file
        Parameters
        ----------
        file_name : 'sting'
            File name for agents pickle file

        Returns
        -------

        """
        if not file_name.endswith('.pkl'):
            file_name = file_name + '.pkl'

        self.df.to_pickle(file_name)


class Solar_Agents(Agents):
    """
    Solar Agents class instance
    """
    def __init__(self, agents_df, scenario_df):
        """
        Initialize Solar Agents Class
        Parameters
        ----------
        agents_df : 'pd.df'
            Pandas Dataframe containing agents and their attributes.
            Index = agent ids, columns = agent attributes
        scenario_df : 'pd.df'
            Pandas Dataframe containing scenario/solar specific attributes

        Returns
        -------
        agent_df : 'pd.df'
            Agents DataFrame
        agent_ids : 'ndarray'
            Array of agent ids
        agent_attrs : 'ndarray'
            Array of agent attributes
        attrs_types : 'pd.Series'
            Array of dtypes for each attribute
        """
        Agents.__init__(self, agents_df)
        self.add_attrs(scenario_df)
        self.update_attrs
