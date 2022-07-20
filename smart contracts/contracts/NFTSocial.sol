// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

contract NFTSocial {

    // Events
    event PostCreated (bytes32 indexed postId, address indexed postOwner, bytes32 indexed parentId, bytes32 contentId, bytes32 categoryId);
    event ContentAdded (bytes32 indexed contentId, string contentUri);
    event Voted (bytes32 indexed postId, address indexed postOwner, address indexed voter, uint80 reputationPostOwner, uint80 reputationVoter, int40 postVotes, bool up, uint8 reputationAmount);
    event CategoryCreated (bytes32 indexed categoryId, string category);
    
    // Data structure for a post
    struct post {
        address postOwner;
        bytes32 parentPost; // Used to incorporate commenting on a post
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
        require (postRegistry[_postId].postOwner != _voter, "User cannot vote on their own post");
        require (voteRegistry[_voter][_postId] == false, "User already voted on this post");
        require (validateReputationChange(_voter,_category,_reputationAdded) == true, "This wallet address cannot add this amount of reputation points");
        postRegistry[_postId].votes += 1;
        reputationRegistry[_contributor][_category] += _reputationAdded;
        voteRegistry[_voter][_postId] = true;
        emit Voted(_postId, _contributor, _voter, reputationRegistry[_contributor][_category], reputationRegistry[_voter][_category], postRegistry[_postId].votes, true, _reputationAdded);
    }

    // Function to allow "disliking" or "downvoting" a post
    function voteDown(bytes32 _postId, uint8 _reputationTaken) external {
        address _voter = msg.sender;
        bytes32 _category = postRegistry[_postId].categoryId;
        address _contributor = postRegistry[_postId].postOwner;
        require (postRegistry[_postId].postOwner != _voter, "User cannot vote on their own post");
        require (voteRegistry[_voter][_postId] == false, "User already voted on this post");
        require (validateReputationChange(_voter,_category,_reputationTaken) == true, "This wallet address cannot take this amount of reputation points");
        postRegistry[_postId].votes >= 1 ? postRegistry[_postId].votes -= 1 : postRegistry[_postId].votes = 0;
        reputationRegistry[_contributor][_category] >= _reputationTaken ? reputationRegistry[_contributor][_category] -= _reputationTaken : reputationRegistry[_contributor][_category] = 0;
        voteRegistry[_voter][_postId] = true;
        emit Voted(_postId, _contributor, _voter, reputationRegistry[_contributor][_category], reputationRegistry[_voter][_category], postRegistry[_postId].votes, false, _reputationTaken);
    }

    // Function to validate the reputation change of a particular user in a particular post category
    function validateReputationChange(address _sender, bytes32 _categoryId, uint8 _reputationAdded) internal view returns (bool _result) {
        uint80 _reputation = reputationRegistry[_sender][_categoryId];
        if (_reputation < 2) {
            _reputationAdded == 1 ? _result = true : _result = false; // if the sender has a reputation of 0 in that category, do not validate
        }
        else {
            2**_reputationAdded <= _reputation ? _result = true : _result = false; // if 2^1 is less than reputation of the sender in that category, validate, else do not
        }
    }

    // Function to add a new category for post discussion
    function addCategory(string calldata _category) external {
        bytes32 _category = keccak256(abi.encode(_category));
        categoryRegistry[_categoryId] = _category;
        emit CategoryCreated(_category, _category);
    }
}