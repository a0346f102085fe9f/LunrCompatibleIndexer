# LunrCompatibleIndexer

The JavaScript-based indexer lunr.js comes with is painfully slow and is unfit for large datasets. This is a native reimplementation that is mostly compatible.

It will use every .txt file in the working directory. It will not traverse subdirectories. It will write the results into `index_v1.1.json` file.

I highly recommend using a ramdisk as a working directory. Use the awesome ImDisk software if you are on Windows, or /dev/shm if you are on Linux.

The index produced *does not* use the save/load functionality integrated into lunr.js -- you don't need to modify lunr.js in any way but you still need quite a bit of custom external code: [custom init](https://github.com/a0346f102085fe9f/IAS/blob/9664f4a0d24443cb9c9a9c75af67eef2bb12964f/index.html#L3120-L3220), [custom stemmer](https://github.com/a0346f102085fe9f/IAS/blob/9664f4a0d24443cb9c9a9c75af67eef2bb12964f/index.html#L2232-L2416) and more...

