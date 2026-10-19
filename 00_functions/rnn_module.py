import torch
import torch.nn as nn
from torch.nn.utils.rnn import pack_sequence


class AmmoniaRNN(nn.Module):
    """Recurrent neural network for plot-level ammonia emission sequences."""

    def __init__(
        self,
        input_size,
        output_size,
        hidden_size,
        num_layers,
        nonlinearity,
        bidirectional,
        cat_dims=None,
        embedding_dims=None,
    ):
        """Initialize the fixed-MLP recurrent architecture."""
        super(AmmoniaRNN, self).__init__()

        D = 2 if bidirectional else 1

        self.embeddings = nn.ModuleList(
            [
                nn.Embedding(num_embeddings=cat_dim, embedding_dim=embed_dim)
                for cat_dim, embed_dim in zip(cat_dims, embedding_dims)
            ]
        )

        input_size = input_size - len(cat_dims) + sum(embedding_dims)

        self.rnn = nn.RNN(
            input_size,
            hidden_size,
            num_layers=num_layers,
            nonlinearity=nonlinearity,
            bidirectional=bidirectional,
        )

        self.fc1 = nn.Linear(hidden_size * D, 6)
        self.fc2 = nn.Linear(6, output_size)

        self.relu = nn.ReLU()

    def forward(self, list_x_train):
        """Predict all time steps for a collection of plot sequences."""
        list_x = []

        for x in list_x_train:
            x_continuous = x[0]
            x_categoricals = x[1]

            x_embeds = [
                embed(x_cat) for embed, x_cat in zip(self.embeddings, x_categoricals)
            ]

            x_final = torch.cat([x_continuous] + x_embeds, dim=-1)

            list_x.append(x_final)

        packed_x = pack_sequence(list_x, enforce_sorted=False)

        h, _ = self.rnn(packed_x)

        h = h.data

        out = self.fc1(h)
        out = self.relu(out)

        out = self.fc2(out)

        return out


def build_mlp(input_size, hidden_layers, output_size, activation=nn.ReLU):
    """Build a feed-forward network from the requested layer sizes."""
    layers = []
    sizes = [input_size] + hidden_layers + [output_size]

    for i in range(len(sizes) - 1):
        layers.append(nn.Linear(sizes[i], sizes[i + 1]))
        if i < len(sizes) - 2:
            layers.append(activation())

    return nn.Sequential(*layers)


class AmmoniaRNN_dev(nn.Module):
    """Development variant with a configurable post-RNN MLP."""

    def __init__(
        self,
        input_size,
        output_size,
        hidden_size,
        num_layers,
        nonlinearity,
        bidirectional,
        mlp_layers=[6],
        cat_dims=None,
        embedding_dims=None,
    ):
        """Initialize the configurable-MLP recurrent architecture."""
        super(AmmoniaRNN_dev, self).__init__()

        D = 2 if bidirectional else 1

        self.embeddings = nn.ModuleList(
            [
                nn.Embedding(num_embeddings=cat_dim, embedding_dim=embed_dim)
                for cat_dim, embed_dim in zip(cat_dims, embedding_dims)
            ]
        )

        input_size = input_size - len(cat_dims) + sum(embedding_dims)

        self.rnn = nn.RNN(
            input_size,
            hidden_size,
            num_layers=num_layers,
            nonlinearity=nonlinearity,
            bidirectional=bidirectional,
        )

        self.mlp = build_mlp(
            input_size=hidden_size * D,
            hidden_layers=mlp_layers,
            output_size=output_size,
        )

    def forward(self, list_x_train):
        """Predict sequences with the configurable-MLP model."""
        list_x = []

        for x in list_x_train:
            x_continuous = x[0]
            x_categoricals = x[1]

            x_embeds = [
                embed(x_cat) for embed, x_cat in zip(self.embeddings, x_categoricals)
            ]

            x_final = torch.cat([x_continuous] + x_embeds, dim=-1)

            list_x.append(x_final)

        packed_x = pack_sequence(list_x, enforce_sorted=False)

        h, _ = self.rnn(packed_x)

        h = h.data

        out = self.mlp(h)

        return out
