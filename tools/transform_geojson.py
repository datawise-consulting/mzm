import sys
import json
import pandas as pd
import datetime


def normalize_properties(
    spatial_data: json,
    features_key: str = "features",
    properties_key: str = "properties",
    field_id_key: list = ["fid"],
) -> pd.DataFrame:
    """Extract 'properties' item of geojson data and return as unpivoted pd.DataFrame."""
    df = pd.json_normalize(spatial_data[features_key])
    # select columns containing "properties" or other key
    properties = df[[col for col in df.columns if properties_key in col]]
    # drop key from column name
    properties = properties.rename(
        {col: col.replace("properties.", "") for col in df.columns}, axis=1
    )
    # unpivot other columns than "fid"
    properties_long = properties.melt(field_id_key)
    properties_long = properties_long.set_index(field_id_key, drop=True)
    return properties_long


def drop_properties(
    spatial_data: json,
    features_key: str = "features",
    properties_key: str = "properties",
    field_id_key: list = ["fid"],
) -> json:
    """Return a copy of geojson data with all properties but field_id removed."""
    # copy original geojson so we don't overwrite it
    features = spatial_data[features_key]
    new_features = []
    for f in features:
        # preserve exact copy of each feature except that properties_key: only field_id_key
        nf = f.copy()
        nf = nf.update({fik: f[properties_key][fik] for fik in field_id_key})
        new_features.append(nf)
    # create new geojson with new_features in place of original
    new_spatial = spatial_data.copy()
    new_spatial[features_key] = new_features
    return new_spatial


datestamp = datetime.date.today().strftime("%Y%m%d")

if __name__ == "__main__":
    geofile = sys.argv[1]
    # can't we do these with default args?
    features_key = sys.argv[2] if len(sys.argv) > 2 else "features"
    properties_key = sys.argv[3] if len(sys.argv) > 3 else "properties"
    field_id_key = sys.argv[4:] if len(sys.argv) > 4 else ["fid"]

    with open(geofile) as f:
        geo = json.load(f)
        properties_file = normalize_properties(
            geo,
            features_key=features_key,
            properties_key=properties_key,
            field_id_key=field_id_key,
        )
        properties_filename = geofile.replace(
            ".geojson", " joinme " + datestamp + ".csv"
        )
        properties_file.to_csv(properties_filename)
        spatial_file = drop_properties(
            geo,
            features_key=features_key,
            properties_key=properties_key,
            field_id_key=field_id_key,
        )
        spatial_filename = geofile.replace(
            ".geojson", " joinme " + datestamp + ".geojson"
        )
    # json dump requires file open
    with open(spatial_filename, "w") as jf:
        json.dump(spatial_file, jf)
