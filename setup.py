from setuptools import setup, find_packages

setup(
    name="coingecko_pipeline",  # The name of your package.
    version="0.1",              # The version number of your package.
    packages=find_packages(),   # Finds all sub-packages automatically.
    install_requires=[          # External dependencies that will be installed with your package.
        'requests',             # For making HTTP requests.
        'pandas',               # For data manipulation.
        'psycopg2-binary',      # For PostgreSQL database connection.
        'python-dotenv'         # For managing environment variables.
    ],
)
