module Cardano.Api.Alonzo.Render
  ( renderScriptIntegrityHash
  , renderMissingRedeemers
  , renderScriptPurpose
  , renderBadInputsUTxOErr
  , renderValueNotConservedErr
  , renderTxId
  ) where

import           Cardano.Ledger.Crypto (StandardCrypto)
import           Cardano.Ledger.Shelley.API hiding (ShelleyBasedEra)
import           Cardano.Prelude
import           Data.Aeson (ToJSON (..), Value(..), object, (.=))
import           Data.Aeson.Types (Pair)
import           Ouroboros.Consensus.Shelley.Ledger hiding (TxId)
import           Prelude hiding ((.), map, show)

import qualified Cardano.Api.Address as Api
import qualified Cardano.Api.Certificate as Api
import qualified Cardano.Api.Ledger.Mary as Api
import qualified Cardano.Api.Script as Api
import qualified Cardano.Api.SerialiseRaw as Api
import qualified Cardano.Api.SerialiseTextEnvelope as Api
import qualified Cardano.Api.TxBody as Api
import qualified Cardano.Crypto.Hash.Class as Crypto
import qualified Cardano.Ledger.Alonzo.Tx as Alonzo
import qualified Cardano.Ledger.SafeHash as SafeHash
import qualified Data.Aeson as Aeson
import qualified Data.Aeson.Key as Aeson
import qualified Data.Set as Set
import qualified Ouroboros.Consensus.Ledger.SupportsMempool as Consensus

renderScriptIntegrityHash :: Maybe (Alonzo.ScriptIntegrityHash StandardCrypto) -> Value
renderScriptIntegrityHash (Just witPPDataHash) =
  String . Crypto.hashToTextAsHex $ SafeHash.extractHash witPPDataHash
renderScriptIntegrityHash Nothing = Aeson.Null

renderMissingRedeemers :: [(Alonzo.ScriptPurpose StandardCrypto, ScriptHash StandardCrypto)] -> Value
renderMissingRedeemers scripts = object $ map renderTuple  scripts
  where
    renderTuple :: (Alonzo.ScriptPurpose StandardCrypto, ScriptHash StandardCrypto) -> Pair
    renderTuple (scriptPurpose, sHash) =
      Aeson.fromText (Api.serialiseToRawBytesHexText $ Api.ScriptHash sHash) .= renderScriptPurpose scriptPurpose

renderScriptPurpose :: Alonzo.ScriptPurpose StandardCrypto -> Value
renderScriptPurpose (Alonzo.Minting pid) = object
  [ "minting" .= toJSON (Api.PolicyID pid)
  ]
renderScriptPurpose (Alonzo.Spending txin) = object
  [ "spending" .= Api.fromShelleyTxIn txin
  ]
renderScriptPurpose (Alonzo.Rewarding rwdAcct) = object
  [ "rewarding" .= String (Api.serialiseAddress $ Api.fromShelleyStakeAddr rwdAcct)
  ]
renderScriptPurpose (Alonzo.Certifying cert) = object
  [ "certifying" .= toJSON (Api.textEnvelopeDefaultDescr $ Api.fromShelleyCertificate cert)
  ]

renderBadInputsUTxOErr ::  Set (TxIn era) -> Value
renderBadInputsUTxOErr txIns
  | Set.null txIns = String "The transaction contains no inputs."
  | otherwise = String "The transaction contains inputs that do not exist in the UTxO set."

renderValueNotConservedErr :: Show val => val -> val -> Value
renderValueNotConservedErr consumed produced = String $
  "This transaction consumed " <> show consumed <> " but produced " <> show produced

renderTxId :: Consensus.TxId (GenTx (ShelleyBlock protocol era)) -> Text
renderTxId = error "TODO implement"
