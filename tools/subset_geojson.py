import sys
import json

if __name__ == "__main__":
    infile = sys.argv[1]
    outfile = sys.argv[2]
    filter_string = sys.argv[3]
    if len(sys.argv) > 4:
        filter_field = sys.argv[4]
    else:
        filter_field = "SITECITY"

    with open(infile, "r") as f:
        data = json.load(f)
        print(f"loaded {infile} with {len(data['features'])} features")

    data["features"] = [
        x for x in data["features"] if x["properties"][filter_field] == filter_string
    ]
    print(
        f"filtered features where {filter_field} = {filter_string}. returned {len(data['features'])} rows."
    )

    with open(outfile, "w") as f:
        json.dump(data, f)

    print(f"wrote to {outfile}")
