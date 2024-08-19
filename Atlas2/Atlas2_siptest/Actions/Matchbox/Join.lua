--  Join.lua
--  Matchbox
--  Created by Shark on 2020/9/28.
--  Copyright © 2020 HWTE. All rights reserved.

-- used to generate a dummy Join node when test plan does not have an ending node without Thread.
-- for example,
--
--     A1 --> A2
--   /
-- X
--   \
--     B1 --> B2
--
-- A2 and B2 will both generate globals and condition table, and returned in its resolvable.
-- If we just end here for test plan execution, Teardown after this will not get globals/conditions because there is no node to merge them.
-- So here we can add a dummy join node after them and do the MergeTable (see MergeTable.lua) and generate a resolvable returning globals and conditions to group.lua so they could be used by Teardown.
-- the example above will looks like this with Join:
--     A1 --> A2 --     mergeGlobal
--   /              \ /               \
-- X                                    JOIN
--   \              / \               /
--     B1 --> B2 --     mergeCondition

function main(globals, conditions)
    return globals, conditions
end
