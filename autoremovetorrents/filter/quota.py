#-*- coding:utf-8 -*-

from .filter import Filter
# from .. import logger


class QuotaFilter(Filter):
    def __init__(self, all, ac, re):
        Filter.__init__(self, all, ac, re)

    def apply(self, torrents):
        # Pick accepted torrents
        accepts = set()
        if self._all: # Accept all torrents
            accepts = set(torrents)
        elif len(self._accept) > 0: # Accept specific quota torrents (quota)
            for torrent in torrents:
                if torrent.ratio > self._accept[0]['ratio'] or torrent.seeding_time > self._accept[1]['seeding_time']:
                    accepts.add(torrent)

        return accepts