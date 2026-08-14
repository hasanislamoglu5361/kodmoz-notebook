# API models

Every Pydantic v2 request/response model in `open_notebook/api/models.py`. Fields are extracted from the upstream source; `Field(...)` defaults are included when present. Models the mobile app deserialises are marked ✓ in the **Used by app** column.

> Counted: **60 models.** Generated from `api/_index.json`.

## `NotebookCreate` (BaseModel) ✓

| Field | Type | Field() default |
|---|---|---|
| `name` | `str` | `..., description="Name of the notebook"` |
| `description` | `str` | `default="", description="Description of the notebook"` |

## `NotebookUpdate` (BaseModel) ✓

| Field | Type | Field() default |
|---|---|---|
| `name` | `Optional[str]` | `None, description="Name of the notebook"` |
| `description` | `Optional[str]` | `None, description="Description of the notebook"` |

## `NotebookResponse` (BaseModel) ✓

| Field | Type | Field() default |
|---|---|---|
| `id` | `str` | `` |
| `name` | `str` | `` |
| `description` | `str` | `` |
| `archived` | `bool` | `` |
| `created` | `str` | `` |
| `updated` | `str` | `` |
| `source_count` | `int` | `` |
| `note_count` | `int` | `` |

## `RecentlyViewedResponse` (BaseModel) ✓

| Field | Type | Field() default |
|---|---|---|
| `type` | `Literal["notebook", "source"]` | `` |
| `id` | `str` | `` |
| `title` | `str` | `` |
| `last_viewed_at` | `str` | `` |

## `SearchRequest` (BaseModel) —

| Field | Type | Field() default |
|---|---|---|
| `query` | `str` | `..., description="Search query"` |
| `type` | `Literal["text", "vector"]` | `"text", description="Search type"` |
| `limit` | `int` | `100, description="Maximum number of results", ge=1, le=1000` |
| `search_sources` | `bool` | `True, description="Include sources in search"` |
| `search_notes` | `bool` | `True, description="Include notes in search"` |

## `SearchResponse` (BaseModel) —

| Field | Type | Field() default |
|---|---|---|
| `results` | `List[Dict[str, Any]]` | `..., description="Search results"` |
| `total_count` | `int` | `..., description="Total number of results"` |
| `search_type` | `str` | `..., description="Type of search performed"` |

## `AskRequest` (BaseModel) —

| Field | Type | Field() default |
|---|---|---|
| `question` | `str` | `..., description="Question to ask the knowledge base"` |
| `strategy_model` | `str` | `..., description="Model ID for query strategy"` |
| `answer_model` | `str` | `..., description="Model ID for individual answers"` |
| `final_answer_model` | `str` | `..., description="Model ID for final answer"` |

## `AskResponse` (BaseModel) —

| Field | Type | Field() default |
|---|---|---|
| `answer` | `str` | `..., description="Final answer from the knowledge base"` |
| `question` | `str` | `..., description="Original question"` |

## `ModelCreate` (BaseModel) —

| Field | Type | Field() default |
|---|---|---|
| `name` | `str` | `..., description="Model name (e.g., gpt-5-mini, claude, gemini)"` |

## `ModelResponse` (BaseModel) ✓

| Field | Type | Field() default |
|---|---|---|
| `id` | `str` | `` |
| `name` | `str` | `` |
| `provider` | `str` | `` |
| `type` | `str` | `` |
| `created` | `str` | `` |
| `updated` | `str` | `` |

## `DefaultModelsResponse` (BaseModel) —

_No scalar fields._

## `ProviderAvailabilityResponse` (BaseModel) —

| Field | Type | Field() default |
|---|---|---|
| `available` | `List[str]` | `..., description="List of available providers"` |
| `unavailable` | `List[str]` | `..., description="List of unavailable providers"` |

## `TransformationCreate` (BaseModel) ✓

| Field | Type | Field() default |
|---|---|---|
| `name` | `str` | `..., description="Transformation name"` |
| `title` | `str` | `..., description="Display title for the transformation"` |
| `prompt` | `str` | `..., description="The transformation prompt"` |

## `TransformationUpdate` (BaseModel) ✓

| Field | Type | Field() default |
|---|---|---|
| `name` | `Optional[str]` | `None, description="Transformation name"` |
| `prompt` | `Optional[str]` | `None, description="The transformation prompt"` |

## `TransformationResponse` (BaseModel) ✓

| Field | Type | Field() default |
|---|---|---|
| `id` | `str` | `` |
| `name` | `str` | `` |
| `title` | `str` | `` |
| `description` | `str` | `` |
| `prompt` | `str` | `` |
| `apply_default` | `bool` | `` |
| `created` | `str` | `` |
| `updated` | `str` | `` |

## `TransformationExecuteRequest` (BaseModel) —

| Field | Type | Field() default |
|---|---|---|
| `input_text` | `str` | `..., description="Text to transform"` |

## `TransformationExecuteResponse` (BaseModel) —

| Field | Type | Field() default |
|---|---|---|
| `output` | `str` | `..., description="Transformed text"` |
| `transformation_id` | `str` | `..., description="ID of the transformation used"` |
| `model_id` | `Optional[str]` | `None, description="Model ID used"` |

## `DefaultPromptResponse` (BaseModel) —

_No scalar fields._

## `DefaultPromptUpdate` (BaseModel) —

_No scalar fields._

## `NoteCreate` (BaseModel) ✓

| Field | Type | Field() default |
|---|---|---|
| `title` | `Optional[str]` | `None, description="Note title"` |
| `content` | `str` | `..., description="Note content"` |
| `note_type` | `Optional[str]` | `"human", description="Type of note (human, ai)"` |

## `NoteUpdate` (BaseModel) ✓

| Field | Type | Field() default |
|---|---|---|
| `title` | `Optional[str]` | `None, description="Note title"` |
| `content` | `Optional[str]` | `None, description="Note content"` |
| `note_type` | `Optional[str]` | `None, description="Type of note (human, ai)"` |

## `NoteResponse` (BaseModel) ✓

| Field | Type | Field() default |
|---|---|---|
| `id` | `str` | `` |
| `title` | `Optional[str]` | `` |
| `content` | `Optional[str]` | `` |
| `note_type` | `Optional[str]` | `` |
| `created` | `str` | `` |
| `updated` | `str` | `` |

## `EmbedRequest` (BaseModel) —

| Field | Type | Field() default |
|---|---|---|
| `item_id` | `str` | `..., description="ID of the item to embed"` |
| `item_type` | `str` | `..., description="Type of item (source, note)"` |

## `EmbedResponse` (BaseModel) —

| Field | Type | Field() default |
|---|---|---|
| `success` | `bool` | `..., description="Whether embedding was successful"` |
| `message` | `str` | `..., description="Result message"` |
| `item_id` | `str` | `..., description="ID of the item that was embedded"` |
| `item_type` | `str` | `..., description="Type of item that was embedded"` |

## `RebuildRequest` (BaseModel) —

| Field | Type | Field() default |
|---|---|---|
| `include_sources` | `bool` | `True, description="Include sources in rebuild"` |
| `include_notes` | `bool` | `True, description="Include notes in rebuild"` |
| `include_insights` | `bool` | `True, description="Include insights in rebuild"` |

## `RebuildResponse` (BaseModel) —

| Field | Type | Field() default |
|---|---|---|
| `command_id` | `str` | `..., description="Command ID to track progress"` |
| `total_items` | `int` | `..., description="Estimated number of items to process"` |
| `message` | `str` | `..., description="Status message"` |

## `RebuildProgress` (BaseModel) —

| Field | Type | Field() default |
|---|---|---|
| `processed` | `int` | `..., description="Number of items processed"` |
| `total` | `int` | `..., description="Total items to process"` |
| `percentage` | `float` | `..., description="Progress percentage"` |

## `RebuildStats` (BaseModel) —

| Field | Type | Field() default |
|---|---|---|
| `sources` | `int` | `0, description="Sources processed"` |
| `notes` | `int` | `0, description="Notes processed"` |
| `insights` | `int` | `0, description="Insights processed"` |
| `failed` | `int` | `0, description="Failed items"` |

## `RebuildStatusResponse` (BaseModel) —

| Field | Type | Field() default |
|---|---|---|
| `command_id` | `str` | `..., description="Command ID"` |
| `status` | `str` | `..., description="Status: queued, running, completed, failed"` |

## `SettingsResponse` (BaseModel) —

_No scalar fields._

## `SettingsUpdate` (BaseModel) —

_No scalar fields._

## `AssetModel` (BaseModel) —

_No scalar fields._

## `SourceCreate` (BaseModel) ✓

| Field | Type | Field() default |
|---|---|---|
| `type` | `str` | `..., description="Source type: link, upload, or text"` |
| `url` | `Optional[str]` | `None, description="URL for link type"` |
| `file_path` | `Optional[str]` | `None, description="File path for upload type"` |
| `content` | `Optional[str]` | `None, description="Text content for text type"` |
| `title` | `Optional[str]` | `None, description="Source title"` |
| `embed` | `bool` | `False, description="Whether to embed content for vector search"` |

## `SourceUpdate` (BaseModel) ✓

| Field | Type | Field() default |
|---|---|---|
| `title` | `Optional[str]` | `None, description="Source title"` |
| `topics` | `Optional[List[str]]` | `None, description="Source topics"` |

## `SourceResponse` (BaseModel) ✓

| Field | Type | Field() default |
|---|---|---|
| `id` | `str` | `` |
| `title` | `Optional[str]` | `` |
| `topics` | `Optional[List[str]]` | `` |
| `asset` | `Optional[AssetModel]` | `` |
| `full_text` | `Optional[str]` | `` |
| `embedded` | `bool` | `` |
| `embedded_chunks` | `int` | `` |
| `created` | `str` | `` |
| `updated` | `str` | `` |

## `SourceListResponse` (BaseModel) ✓

| Field | Type | Field() default |
|---|---|---|
| `id` | `str` | `` |
| `title` | `Optional[str]` | `` |
| `topics` | `Optional[List[str]]` | `` |
| `asset` | `Optional[AssetModel]` | `` |
| `embedded` | `bool  # Boolean flag indicating if source has embeddings` | `` |
| `embedded_chunks` | `int  # Number of embedded chunks` | `` |
| `insights_count` | `int` | `` |
| `created` | `str` | `` |
| `updated` | `str` | `` |

## `SourceInsightResponse` (BaseModel) ✓

| Field | Type | Field() default |
|---|---|---|
| `id` | `str` | `` |
| `source_id` | `str` | `` |
| `insight_type` | `str` | `` |
| `content` | `str` | `` |

## `InsightCreationResponse` (BaseModel) —

| Field | Type | Field() default |
|---|---|---|
| `source_id` | `str` | `` |
| `transformation_id` | `str` | `` |

## `SaveAsNoteRequest` (BaseModel) —

| Field | Type | Field() default |
|---|---|---|
| `notebook_id` | `Optional[str]` | `None, description="Notebook ID to add note to"` |

## `CreateSourceInsightRequest` (BaseModel) —

| Field | Type | Field() default |
|---|---|---|
| `transformation_id` | `str` | `..., description="ID of transformation to apply"` |

## `SourceStatusResponse` (BaseModel) —

| Field | Type | Field() default |
|---|---|---|
| `status` | `Optional[str]` | `None, description="Processing status"` |
| `message` | `str` | `..., description="Descriptive message about the status"` |
| `command_id` | `Optional[str]` | `None, description="Command ID if available"` |

## `ErrorResponse` (BaseModel) —

| Field | Type | Field() default |
|---|---|---|
| `error` | `str` | `` |
| `message` | `str` | `` |

## `SetApiKeyRequest` (BaseModel) —

| Field | Type | Field() default |
|---|---|---|
| `api_key` | `Optional[str]` | `None, description="API key for the provider"` |
| `endpoint` | `Optional[str]` | `None, description="Endpoint URL for Azure OpenAI"` |
| `api_version` | `Optional[str]` | `None, description="API version for Azure OpenAI"` |

## `ApiKeyStatusResponse` (BaseModel) —

_No scalar fields._

## `TestConnectionResponse` (BaseModel) —

| Field | Type | Field() default |
|---|---|---|
| `provider` | `str` | `..., description="Provider name that was tested"` |
| `success` | `bool` | `..., description="Whether connection test succeeded"` |
| `message` | `str` | `..., description="Result message with details"` |

## `MigrateFromEnvRequest` (BaseModel) —

_No scalar fields._

## `MigrationResult` (BaseModel) —

| Field | Type | Field() default |
|---|---|---|
| `message` | `str` | `..., description="Summary message"` |

## `ProviderInfoResponse` (BaseModel) —

| Field | Type | Field() default |
|---|---|---|
| `name` | `str` | `..., description="Provider identifier (e.g. openai)"` |
| `display_name` | `str` | `..., description="Human-friendly provider name"` |

## `CapabilitiesResponse` (BaseModel) —

_No scalar fields._

## `CreateCredentialRequest` (BaseModel) —

| Field | Type | Field() default |
|---|---|---|
| `name` | `str` | `..., description="Credential name"` |
| `api_key` | `Optional[str]` | `None, description="API key (stored encrypted)"` |
| `base_url` | `Optional[str]` | `None, description="Base URL"` |
| `endpoint` | `Optional[str]` | `None, description="Endpoint URL (Azure)"` |
| `api_version` | `Optional[str]` | `None, description="API version (Azure)"` |
| `endpoint_llm` | `Optional[str]` | `None, description="LLM endpoint"` |
| `endpoint_embedding` | `Optional[str]` | `None, description="Embedding endpoint"` |
| `endpoint_stt` | `Optional[str]` | `None, description="STT endpoint"` |
| `endpoint_tts` | `Optional[str]` | `None, description="TTS endpoint"` |
| `project` | `Optional[str]` | `None, description="Project ID (Vertex)"` |
| `location` | `Optional[str]` | `None, description="Location (Vertex)"` |

## `UpdateCredentialRequest` (BaseModel) —

| Field | Type | Field() default |
|---|---|---|
| `name` | `Optional[str]` | `None, description="Credential name"` |
| `modalities` | `Optional[List[str]]` | `None, description="Supported modalities"` |
| `api_key` | `Optional[str]` | `None, description="API key (stored encrypted)"` |
| `base_url` | `Optional[str]` | `None, description="Base URL"` |
| `endpoint` | `Optional[str]` | `None, description="Endpoint URL"` |
| `api_version` | `Optional[str]` | `None, description="API version"` |
| `endpoint_llm` | `Optional[str]` | `None, description="LLM endpoint"` |
| `endpoint_embedding` | `Optional[str]` | `None, description="Embedding endpoint"` |
| `endpoint_stt` | `Optional[str]` | `None, description="STT endpoint"` |
| `endpoint_tts` | `Optional[str]` | `None, description="TTS endpoint"` |
| `project` | `Optional[str]` | `None, description="Project ID"` |
| `location` | `Optional[str]` | `None, description="Location"` |
| `credentials_path` | `Optional[str]` | `None, description="Credentials path"` |

## `CredentialResponse` (BaseModel) ✓

| Field | Type | Field() default |
|---|---|---|
| `id` | `str` | `` |
| `name` | `str` | `` |
| `provider` | `str` | `` |
| `modalities` | `List[str]` | `` |
| `created` | `str` | `` |
| `updated` | `str` | `` |

## `CredentialDeleteResponse` (BaseModel) —

| Field | Type | Field() default |
|---|---|---|
| `message` | `str` | `` |

## `DiscoveredModelResponse` (BaseModel) —

| Field | Type | Field() default |
|---|---|---|
| `name` | `str` | `` |
| `provider` | `str` | `` |

## `DiscoverModelsResponse` (BaseModel) —

| Field | Type | Field() default |
|---|---|---|
| `credential_id` | `str` | `` |
| `provider` | `str` | `` |
| `discovered` | `List[DiscoveredModelResponse]` | `` |

## `RegisterModelData` (BaseModel) —

| Field | Type | Field() default |
|---|---|---|
| `name` | `str` | `` |
| `provider` | `str` | `` |
| `model_type` | `str  # Required: user specifies the type` | `` |

## `RegisterModelsRequest` (BaseModel) —

| Field | Type | Field() default |
|---|---|---|
| `models` | `List[RegisterModelData]` | `` |

## `RegisterModelsResponse` (BaseModel) —

| Field | Type | Field() default |
|---|---|---|
| `created` | `int` | `` |
| `existing` | `int` | `` |

## `NotebookDeletePreview` (BaseModel) —

| Field | Type | Field() default |
|---|---|---|
| `notebook_id` | `str` | `..., description="ID of the notebook"` |
| `notebook_name` | `str` | `..., description="Name of the notebook"` |
| `note_count` | `int` | `..., description="Number of notes that will be deleted"` |

## `NotebookDeleteResponse` (BaseModel) —

| Field | Type | Field() default |
|---|---|---|
| `message` | `str` | `..., description="Success message"` |
| `deleted_notes` | `int` | `..., description="Number of notes deleted"` |
| `deleted_sources` | `int` | `..., description="Number of exclusive sources deleted"` |
