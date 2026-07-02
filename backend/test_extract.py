import os
from dotenv import load_dotenv
load_dotenv()
from services.extractor import ExtractorService

text = """
WT18WVTM LAVADORA LG 18KG BLANCA  620$💵
WD14VV3S6C LAVA/SECA LG 14KG/8KG SILVER  740$💵
"""
print(ExtractorService.extract_from_text(text))
