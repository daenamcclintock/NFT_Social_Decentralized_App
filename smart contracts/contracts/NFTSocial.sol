// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

contract NFTSocial {

    event ContentAdded (bytes32 indexed contentId, string contentUri);
    event Voted (bytes32 indexed postId, address indexed postOwner, address indexed voter, uint80 reputationPostOwner, uint80 reputationVoter, int40 postVotes, bool up, uint8 reputationAmount);
    
    // data structure for a post
    struct post {
        address postOwner;
        bytes32 parentPost; // used to incorporate commenting on a post
        bytes32 contentId;
        int40 votes;
        bytes32 categoryId;
    }

    mapping  (address => mapping (bytes32 => uint80)) reputationRegistry;
    mapping (bytes32 => string) categoryRegistry;
    mapping (bytes32 => string) contentRegistry;
    mapping (bytes32 => post) postRegistry;
    mapping (address => mapping (bytes32 => bool)) voteRegistry;

    // Function to create a post and post it to the blockchain
    function createPost(bytes32 _parentId, string calldata _contentUri, bytes32 _categoryId) external {
        address _owner = msg.sender;
        bytes32 _contentId = keccak256(abi.encode(_contentUri));
        bytes32 _postId = keccak256(abi.encodePacked(_owner,_parentId, _contentId));
        contentRegistry[_contentId] = _contentUri;
        postRegistry[_postId].postOwner = _owner;
        postRegistry[_postId].parentPost = _parentId;
        postRegistry[_postId].contentId = _contentId;
        postRegistry[_postId].categoryId = _categoryId;
        emit ContentAdded(_contentId, _contentUri);
        emit PostCreated (_postId, _owner,_parentId,_contentId,_categoryId);
    }

    // Function to allow "liking" or "upvoting" a post
    function voteUp(bytes32 _postId, uint8 _reputationAdded) external {
        address _voter = msg.sender;
        bytes32 _category = postRegistry[_postId].categoryId;
        address _contributor = postRegistry[_postId].postOwner;
        require(postRegistry[_postId].postOwner != _voter, "you cannot vote on your own posts")
        require(voteRegistry[_voter][_postId] == false, "user already voted on this post")
        require(validateReputationChange(_voter, _category, _reputationAdded) == true, "User address cannot add this number of reputation points")
        postRegistry[_postId].votes += 1;
        reputationRegistry[_contributor][_category] += _reputationAdded;
        voteRegistry[_voter][_postId] = true;
        emit Voted(_postId, _contributor, _voter, reputationRegistry[_contributor][_category], reputationRegistry[_voter][_category], postRegistry[_postId].votes, true, _reputationAdded)
    }
}