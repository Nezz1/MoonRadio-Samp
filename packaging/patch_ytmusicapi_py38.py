"""
Backport otomatis sigma67/ytmusicapi (v1.12+) ke Python 3.8 untuk build Windows 7.
Menyalin paket ytmusicapi terbaru dari venv utama ke venv38 lalu mengganti
sintaks Python 3.9/3.10 (match/case, dataclass kw_only, removeprefix, | union runtime).
"""
import os
import re
import shutil
import sys


def patch_tree(src_dir: str, dst_dir: str):
    if os.path.isdir(dst_dir):
        shutil.rmtree(dst_dir)
    shutil.copytree(src_dir, dst_dir)

    for root, _, files in os.walk(dst_dir):
        for fn in files:
            if not fn.endswith(".py"):
                continue
            p = os.path.join(root, fn)
            with open(p, "r", encoding="utf-8") as f:
                txt = f.read()

            # Pastikan annotations dievaluasi malas (PEP 563)
            txt = re.sub(r"(?m)^\s*from __future__ import annotations\s*\n", "", txt)
            txt = "from __future__ import annotations\n" + txt

            # str.removeprefix("MPLA") -> kompatibel Python 3.8
            txt = txt.replace(
                'channelId.removeprefix("MPLA")',
                '(channelId[4:] if channelId.startswith("MPLA") else channelId)',
            )
            txt = txt.replace("@dataclass(kw_only=True)", "@dataclass")
            txt = txt.replace("credentials: Credentials\n", "credentials: Credentials = None\n")
            txt = txt.replace("TextRun = HyperLink | PlainText", "TextRun = dict")
            txt = txt.replace("class Description(list[DescriptionElement]):", "class Description(list):")
            txt = txt.replace("CaseInsensitiveDict[str]()", "CaseInsensitiveDict()")
            txt = txt.replace(
                "isinstance(header, bytes | bytearray)",
                "isinstance(header, (bytes, bytearray))",
            )
            txt = re.sub(
                r"(\{\s*\"inLibrary\":[^}]+\})\s*\|\s*parse_song_menu_data\(data\)",
                r"{**\1, **parse_song_menu_data(data)}",
                txt,
            )
            txt = txt.replace("def members() -> KeysView[str]:", "def members():")
            txt = txt.replace("def is_oauth(headers: CaseInsensitiveDict[str]) -> bool:", "def is_oauth(headers) -> bool:")
            txt = txt.replace(
                "from typing import ParamSpec, TypeVar",
                "from typing import TypeVar\nParamSpec = TypeVar",
            )
            txt = txt.replace(
                "LibraryOrderType = Literal[\"a_to_z\", \"z_to_a\", \"recently_added\"]",
                "LibraryOrderType = str",
            )

            if fn == "type_alias.py":
                txt = (
                    "from typing import Any, Callable, Dict, List\n"
                    "JsonDict = Dict[str, Any]\n"
                    "JsonList = List[JsonDict]\n"
                    "RequestFuncType = Callable[[str], JsonDict]\n"
                    "RequestFuncBodyType = Callable[[JsonDict], JsonDict]\n"
                    "ParseFuncType = Callable[[JsonList], JsonList]\n"
                    "ParseFuncDictType = Callable[[JsonDict], JsonDict]\n"
                )
            elif fn == "models.py" and "DefaultScope" in txt:
                txt = txt.replace(
                    'DefaultScope = str | Literal["https://www.googleapis.com/auth/youtube"]',
                    "DefaultScope = str",
                ).replace('Bearer = str | Literal["Bearer"]', "Bearer = str")
            elif fn == "_utils.py" and "match rating:" in txt:
                txt = re.sub(
                    r"match rating:\s+case LikeStatus\.LIKE:\s+return \"like/like\"\s+"
                    r"case LikeStatus\.DISLIKE:\s+return \"like/dislike\"\s+"
                    r"case LikeStatus\.INDIFFERENT:\s+return \"like/removelike\"\s+case _:",
                    'if rating == LikeStatus.LIKE:\n        return "like/like"\n'
                    '    elif rating == LikeStatus.DISLIKE:\n        return "like/dislike"\n'
                    '    elif rating == LikeStatus.INDIFFERENT:\n        return "like/removelike"\n'
                    "    else:",
                    txt,
                )
            elif fn == "enums.py" and "match self:" in txt:
                txt = re.sub(
                    r"match self:\s+case PlaylistVoteEditOptions\.EVERYONE_CAN_VOTE:\s+return 1\s+"
                    r"case PlaylistVoteEditOptions\.COLLABORATORS_ONLY:\s+return 2\s+"
                    r"case PlaylistVoteEditOptions\.OFF:\s+return 3",
                    "if self == PlaylistVoteEditOptions.EVERYONE_CAN_VOTE:\n            return 1\n"
                    "        if self == PlaylistVoteEditOptions.COLLABORATORS_ONLY:\n            return 2\n"
                    "        return 3",
                    txt,
                )
            elif fn == "explore.py" and "match browse_id:" in txt:
                old_block = txt[txt.index("match browse_id:") :]
                new_block = (
                    'if browse_id == "FEmusic_new_releases_albums":\n'
                    '                explore["new_releases"] = parse_content_list(contents, parse_album)\n'
                    '            elif browse_id == "FEmusic_moods_and_genres":\n'
                    '                explore["moods_and_genres"] = [\n'
                    '                    {"title": nav(genre, CATEGORY_TITLE), "params": nav(genre, CATEGORY_PARAMS)}\n'
                    "                    for genre in nav(result, CAROUSEL_CONTENTS)\n"
                    "                ]\n"
                    '            elif browse_id == "FEmusic_top_non_music_audio_episodes":\n'
                    '                explore["top_episodes"] = parse_content_list(contents, parse_chart_episode, MMRIR)\n'
                    '            elif browse_id == "FEmusic_new_releases_videos":\n'
                    '                explore["new_videos"] = parse_content_list(contents, parse_video, MTRIR)\n'
                    '            elif browse_id.startswith("VLPL"):\n'
                    '                explore["top_songs"] = {\n'
                    '                    "playlist": browse_id,\n'
                    '                    "items": parse_content_list(contents, parse_chart_song, MRLIR),\n'
                    "                }\n"
                    '            elif browse_id.startswith("VLOLA"):\n'
                    '                explore["trending"] = {\n'
                    '                    "playlist": browse_id,\n'
                    '                    "items": parse_content_list(contents, parse_Trending_item, MRLIR),\n'
                    "                }\n"
                    "        return explore\n"
                ).replace("parse_Trending_item", "parse_trending_item")
                txt = txt[: txt.index("match browse_id:")] + new_block
            elif fn == "songs.py" and 'match parsed_run["type"]:' in txt:
                txt = re.sub(
                    r'match parsed_run\["type"\]:\s+'
                    r'case "album":\s+parsed\["album"\] = data\s+'
                    r'case "artist":\s+parsed\["artists"\] = parsed\.get\("artists", \[\]\)\s+parsed\["artists"\]\.append\(data\)\s+'
                    r'case "views":\s+parsed\["views"\] = data\s+'
                    r'case "duration":\s+parsed\["duration"\] = data\s+parsed\["duration_seconds"\] = parse_duration\(data\)\s+'
                    r'case "year":\s+parsed\["year"\] = data',
                    'rt = parsed_run["type"]\n'
                    '        if rt == "album":\n            parsed["album"] = data\n'
                    '        elif rt == "artist":\n            parsed["artists"] = parsed.get("artists", [])\n            parsed["artists"].append(data)\n'
                    '        elif rt == "views":\n            parsed["views"] = data\n'
                    '        elif rt == "duration":\n            parsed["duration"] = data\n            parsed["duration_seconds"] = parse_duration(data)\n'
                    '        elif rt == "year":\n            parsed["year"] = data',
                    txt,
                )
                idx = txt.find("match current_icon_type:")
                if idx != -1:
                    txt = (
                        txt[:idx]
                        + 'if current_icon_type == "KEEP":\n'
                        '            song_data["pinnedToListenAgain"] = is_toggled\n'
                        '            song_data["listenAgainFeedbackTokens"] = {\n'
                        '                "pin": feedback_token("defaultServiceEndpoint"),\n'
                        '                "unpin": feedback_token("toggledServiceEndpoint"),\n'
                        "            }\n"
                        '        elif current_icon_type == "KEEP_OFF":\n'
                        '            song_data["pinnedToListenAgain"] = True\n'
                        '            song_data["listenAgainFeedbackTokens"] = {\n'
                        '                "pin": feedback_token("toggledServiceEndpoint"),\n'
                        '                "unpin": feedback_token("defaultServiceEndpoint"),\n'
                        "            }\n"
                        '        elif current_icon_type == "BOOKMARK_BORDER":\n'
                        '            song_data["inLibrary"] = is_toggled\n'
                        '            song_data["feedbackTokens"] = {\n'
                        '                "add": feedback_token("defaultServiceEndpoint"),\n'
                        '                "remove": feedback_token("toggledServiceEndpoint"),\n'
                        "            }\n"
                        '        elif current_icon_type == "BOOKMARK":\n'
                        '            song_data["inLibrary"] = True\n'
                        '            song_data["feedbackTokens"] = {\n'
                        '                "add": feedback_token("toggledServiceEndpoint"),\n'
                        '                "remove": feedback_token("defaultServiceEndpoint"),\n'
                        "            }\n"
                        '        elif current_icon_type == "REMOVE_FROM_HISTORY":\n'
                        '            song_data["feedbackToken"] = feedback_token("serviceEndpoint")\n\n'
                        "    return song_data\n\n\n"
                        "def parse_like_status(service: JsonDict) -> str:\n"
                        '    status = ["LIKE", "INDIFFERENT"]\n'
                        '    return status[status.index(service["likeEndpoint"]["status"]) - 1]\n'
                    )

            with open(p, "w", encoding="utf-8", newline="\n") as f:
                f.write(txt)


if __name__ == "__main__":
    src, dst = sys.argv[1], sys.argv[2]
    patch_tree(src, dst)
    print(f"Patched ytmusicapi -> {dst}")
